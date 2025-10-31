Seeding Firestore (development)

This project includes a convenience script to seed a sample `products` document
for development and testing. It uses the Firebase Admin SDK and a service
account JSON key. Do NOT run this with production credentials unless you know
what you're doing.

Steps:

1) Create or download a service account JSON key with Firestore access from
   the Firebase Console or Google Cloud IAM.

2) Export the environment variable to point to the key file:

   On macOS / Linux:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
   ```

   On Windows PowerShell:
   ```powershell
   $env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\path\to\service-account.json'
   ```

3) Install dependencies (Node.js required):

   ```bash
   npm init -y
   npm install firebase-admin
   ```

4) Run the seeding script:

   ```bash
   node tools/seed_firestore.js
   ```

This will upsert a document at `products/sample_mineral_water` with sample fields.

If you prefer to use the Firebase Console UI, you can also manually create a
`products` document with similar fields.

Dev Firestore rules
-------------------
A permissive dev rules file is included at `firestore.rules.dev` for quick local
testing. To use it for emulator or temporary testing, copy the file to your
project's firestore.rules or apply via Firebase Console (ONLY USE FOR TESTING).

Security reminder: Never deploy permissive rules to production and never
commit service-account keys to source control.
