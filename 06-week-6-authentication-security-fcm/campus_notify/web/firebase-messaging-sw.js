importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js'
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js'
);

firebase.initializeApp({
  apiKey: 'AIzaSyD3aDoFUfMSCLk-LLonUd49NCL8kGfU6jU',
  authDomain: 'campus-notify-cc71e.firebaseapp.com',
  projectId: 'campus-notify-cc71e',
  storageBucket: 'campus-notify-cc71e.firebasestorage.app',
  messagingSenderId: '885732918471',
  appId: '1:885732918471:web:2413476198f8681f82eae2',
  measurementId: 'G-WEJPDQ6DZ0'
});

const messaging = firebase.messaging();