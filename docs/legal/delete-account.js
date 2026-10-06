// Self-serve account deletion for VitaMind. Mirrors the app's deletion order:
// sign in, delete the user's Firestore data, then delete the Firebase Auth
// account. Firestore rules only let a signed-in user delete their own data,
// so the cloud data must go before the account does.
import { initializeApp } from 'https://www.gstatic.com/firebasejs/12.19.0/firebase-app.js';
import {
  deleteUser,
  getAuth,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signOut,
} from 'https://www.gstatic.com/firebasejs/12.19.0/firebase-auth.js';
import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  getFirestore,
  limit,
  query,
  writeBatch,
} from 'https://www.gstatic.com/firebasejs/12.19.0/firebase-firestore.js';

// Public web config from lib/firebase_options.dart. These values identify the
// project; access is enforced by Firebase Auth and the Firestore rules.
const app = initializeApp({
  apiKey: 'AIzaSyA7CA2_LpX25NigR7l6QCTxl5kWAvsP320',
  appId: '1:494081190035:web:abc41ea399449e55590566',
  messagingSenderId: '494081190035',
  projectId: 'vitamind-9d46b',
  authDomain: 'vitamind-9d46b.firebaseapp.com',
  storageBucket: 'vitamind-9d46b.firebasestorage.app',
});
const auth = getAuth(app);
const db = getFirestore(app);

// Keep in sync with FirestoreService.deleteUserData.
const USER_COLLECTIONS = ['moods', 'symptoms', 'journals', 'settings'];

const form = document.getElementById('delete-form');
const emailInput = document.getElementById('email');
const passwordInput = document.getElementById('password');
const confirmInput = document.getElementById('confirm');
const submitButton = document.getElementById('delete-button');
const resetButton = document.getElementById('reset-button');
const status = document.getElementById('status');

function showStatus(message, kind) {
  status.textContent = message;
  status.dataset.kind = kind;
}

function setBusy(busy) {
  for (const control of [emailInput, passwordInput, confirmInput, submitButton, resetButton]) {
    control.disabled = busy;
  }
  submitButton.textContent = busy ? 'Deleting…' : 'Delete my account';
}

function friendlyError(error) {
  switch (error?.code) {
    case 'auth/invalid-credential':
    case 'auth/wrong-password':
    case 'auth/user-not-found':
    case 'auth/invalid-email':
      return 'The email or password is incorrect.';
    case 'auth/too-many-requests':
      return 'Too many attempts. Wait a few minutes and try again, or reset your password.';
    case 'auth/network-request-failed':
    case 'unavailable':
      return 'We couldn’t reach the server. Check your connection and try again.';
    default:
      return 'Something went wrong and your account was not deleted. Please try again, or email us.';
  }
}

async function deleteCollection(uid, name) {
  const ref = collection(db, 'users', uid, name);
  for (;;) {
    const snapshot = await getDocs(query(ref, limit(400)));
    if (snapshot.empty) {
      return;
    }
    const batch = writeBatch(db);
    snapshot.docs.forEach((document) => batch.delete(document.ref));
    await batch.commit();
  }
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  if (!form.reportValidity()) {
    return;
  }

  setBusy(true);
  showStatus('Deleting your account…', 'info');
  let signedIn = false;
  try {
    const { user } = await signInWithEmailAndPassword(
      auth,
      emailInput.value.trim(),
      passwordInput.value,
    );
    signedIn = true;
    for (const name of USER_COLLECTIONS) {
      await deleteCollection(user.uid, name);
    }
    await deleteDoc(doc(db, 'users', user.uid));
    await deleteUser(user);
    signedIn = false;

    form.hidden = true;
    showStatus(
      'Your VitaMind account and its cloud data have been deleted. To remove data still on your phone, uninstall VitaMind.',
      'success',
    );
  } catch (error) {
    console.error('VitaMind account deletion failed', error);
    showStatus(friendlyError(error), 'error');
  } finally {
    passwordInput.value = '';
    if (signedIn) {
      await signOut(auth).catch(() => {});
    }
    if (!form.hidden) {
      setBusy(false);
    }
  }
});

resetButton.addEventListener('click', async () => {
  const email = emailInput.value.trim();
  if (!email) {
    showStatus('Enter your email above, then tap “Forgot password?” again.', 'error');
    emailInput.focus();
    return;
  }
  try {
    await sendPasswordResetEmail(auth, email);
  } catch (error) {
    // Don't reveal whether an account exists for this email.
    console.error('VitaMind password reset failed', error);
  }
  showStatus(
    'If a VitaMind account uses that email, a password reset link is on its way. Come back here once you’ve set a new password.',
    'info',
  );
});
