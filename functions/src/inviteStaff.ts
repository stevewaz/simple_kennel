import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

// Configure your email service (SendGrid example)
// For SendGrid: npm install nodemailer-sendgrid-transport
import * as sgTransport from 'nodemailer-sendgrid-transport';

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Configure email transporter (SendGrid)
const transporter = nodemailer.createTransport(
  sgTransport({
    auth: {
      api_key: process.env.SENDGRID_API_KEY || '',
    },
  })
);

// Generate random invite code
function generateInviteCode(): string {
  return Math.random().toString(36).substring(2, 15) +
         Math.random().toString(36).substring(2, 15);
}

// Cloud Function triggered when new invite is created in Firestore
export const sendInviteEmail = functions.firestore
  .document('invites/{inviteId}')
  .onCreate(async (snap, context) => {
    const inviteData = snap.data();
    const inviteId = context.params.inviteId;

    const {
      email,
      tenantId,
      businessName,
    } = inviteData;

    try {
      // Get tenant info for email
      const tenantDoc = await db.collection('tenants').doc(tenantId).get();
      const tenantName = tenantDoc.data()?.businessName || 'Your Company';

      // Generate invite code if not already set
      const inviteCode = inviteData.inviteCode || generateInviteCode();

      // Create signup link with invite code as deep link
      // Format: https://yourapp.com/join?code=XXXXX or app://join?code=XXXXX
      const webSignupLink = `https://stevewaz.github.io/simple_kennel/?invite=${inviteCode}`;
      const iosLink = `runbook://join?invite=${inviteCode}`;
      const androidLink = `runbook://join?invite=${inviteCode}`;

      // Email template
      const mailOptions = {
        from: 'noreply@runbook.app',
        to: email,
        subject: `You're invited to join ${tenantName} on Runbook!`,
        html: `
          <!DOCTYPE html>
          <html>
            <head>
              <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
                .container { max-width: 500px; margin: 0 auto; padding: 20px; }
                .header { background: #7C3AED; color: white; padding: 20px; border-radius: 8px 8px 0 0; text-align: center; }
                .content { background: #f9fafb; padding: 20px; border-radius: 0 0 8px 8px; }
                .button {
                  display: inline-block;
                  background: #7C3AED;
                  color: white;
                  padding: 12px 32px;
                  text-decoration: none;
                  border-radius: 6px;
                  margin: 20px 0;
                  font-weight: 600;
                }
                .code {
                  font-family: monospace;
                  background: white;
                  padding: 10px;
                  border-radius: 4px;
                  text-align: center;
                  font-size: 18px;
                  letter-spacing: 2px;
                  margin: 20px 0;
                }
                .footer { color: #6b7280; font-size: 12px; margin-top: 20px; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h2>You're invited to Runbook!</h2>
                </div>
                <div class="content">
                  <p>Hi there,</p>
                  <p><strong>${tenantName}</strong> has invited you to join their team on <strong>Runbook</strong>.</p>

                  <h3>Download the App & Sign Up</h3>
                  <p>
                    <a href="https://apps.apple.com/app/runbook" target="_blank">📱 iOS App</a> |
                    <a href="https://play.google.com/store/apps/details?id=com.runbook.app" target="_blank">🤖 Android App</a>
                  </p>

                  <h3>Your Invite Code</h3>
                  <div class="code">${inviteCode}</div>
                  <p style="text-align: center; color: #6b7280; font-size: 14px;">
                    Use this code when signing up with your email: <strong>${email}</strong>
                  </p>

                  <p style="text-align: center;">
                    <a href="${webSignupLink}" class="button">Open Invite Link</a>
                  </p>

                  <p style="color: #6b7280; font-size: 14px;">
                    <strong>Steps to join:</strong><br/>
                    1. Download Runbook app (iOS or Android)<br/>
                    2. Sign up with email: <strong>${email}</strong><br/>
                    3. Enter invite code: <strong>${inviteCode}</strong><br/>
                    4. You're in! 🎉
                  </p>

                  <div class="footer">
                    <p>This invite will expire in 30 days.</p>
                    <p>If you didn't expect this invite, you can ignore this email.</p>
                  </div>
                </div>
              </div>
            </body>
          </html>
        `,
      };

      // Send email
      await transporter.sendMail(mailOptions);

      // Update invite document with sent timestamp
      await snap.ref.update({
        inviteCode: inviteCode,
        emailSent: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Invite email sent to ${email}`);
      return { success: true };
    } catch (error) {
      console.error('Error sending invite email:', error);
      throw error;
    }
  });

// Callable function to verify and use invite code
export const verifyInviteCode = functions.https.onCall(
  async (data: { inviteCode: string; email: string }, context) => {
    const { inviteCode, email } = data;

    if (!inviteCode || !email) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing invite code or email'
      );
    }

    try {
      // Find invite in Firestore
      const snapshot = await db
        .collection('invites')
        .where('inviteCode', '==', inviteCode)
        .where('email', '==', email)
        .limit(1)
        .get();

      if (snapshot.empty) {
        throw new functions.https.HttpsError(
          'not-found',
          'Invite code not found'
        );
      }

      const inviteDoc = snapshot.docs[0];
      const invite = inviteDoc.data();

      // Check if already used
      if (invite.used) {
        throw new functions.https.HttpsError(
          'already-exists',
          'This invite has already been used'
        );
      }

      // Check if expired
      const expiresAt = invite.expiresAt.toDate();
      if (new Date() > expiresAt) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'This invite has expired'
        );
      }

      // Mark invite as used
      await inviteDoc.ref.update({
        used: true,
        usedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        tenantId: invite.tenantId,
        email: invite.email,
      };
    } catch (error) {
      console.error('Error verifying invite:', error);
      throw error;
    }
  }
);
