// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import '../css/app.css';

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html';
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import topbar from '../vendor/topbar';

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');

// Show progress bar on live navigation and form submits
topbar.config({
  barColors: { 0: '#00d4aa' },
  shadowColor: 'rgba(0, 0, 0, .3)',
});
window.addEventListener('phx:page-loading-start', (info) => topbar.show());
window.addEventListener('phx:page-loading-stop', (info) => topbar.hide());

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()

// Local Storage Management
const PlayerStorage = {
  // Save player name to local storage
  savePlayerName: (name) => {
    if (name && name.trim()) {
      localStorage.setItem('trivia_buzzer_player_name', name.trim());
    }
  },

  // Get player name from local storage
  getPlayerName: () => {
    return localStorage.getItem('trivia_buzzer_player_name') || '';
  },

  // Clear player name from local storage
  clearPlayerName: () => {
    localStorage.removeItem('trivia_buzzer_player_name');
  },

  // Save player ID for a specific game
  savePlayerId: (gameCode, playerId) => {
    if (gameCode && playerId) {
      localStorage.setItem(
        `trivia_buzzer_player_id_${gameCode}`,
        playerId.toString()
      );
    }
  },

  // Get player ID for a specific game
  getPlayerId: (gameCode) => {
    return localStorage.getItem(`trivia_buzzer_player_id_${gameCode}`) || null;
  },

  // Clear player ID for a specific game
  clearPlayerId: (gameCode) => {
    localStorage.removeItem(`trivia_buzzer_player_id_${gameCode}`);
  },

  // Clear all player data
  clearAll: () => {
    localStorage.removeItem('trivia_buzzer_player_name');
    // Clear all player IDs (we'll iterate through keys)
    Object.keys(localStorage).forEach((key) => {
      if (key.startsWith('trivia_buzzer_player_id_')) {
        localStorage.removeItem(key);
      }
    });
  },
};

// Expose to window for LiveView hooks
window.PlayerStorage = PlayerStorage;

// LiveView hooks for local storage
const Hooks = {
  // Hook to save player name when joining a game
  PlayerName: {
    mounted() {
      // Auto-fill player name from local storage
      const playerNameInput = this.el.querySelector('#player_name');
      if (playerNameInput) {
        const savedName = PlayerStorage.getPlayerName();
        if (savedName) {
          playerNameInput.value = savedName;
        }
      }

      // Handle saving player name when joining game
      this.handleEvent('save_player_name', (data) => {
        PlayerStorage.savePlayerName(data.name);
      });
    },
  },

  // Hook to handle player ID storage and retrieval
  PlayerGame: {
    mounted() {
      // Get the game code from the URL or data attribute
      const gameCode =
        this.el.dataset.gameCode || window.location.pathname.split('/').pop();

      // Check if we have a stored player ID for this game
      const storedPlayerId = PlayerStorage.getPlayerId(gameCode);

      if (storedPlayerId) {
        // Send the stored player ID to the LiveView
        this.pushEvent('restore_player', { player_id: storedPlayerId });
      }

      // Handle storing player ID when joining
      this.handleEvent('store_player_id', (data) => {
        PlayerStorage.savePlayerId(data.game_code, data.player_id);
      });

      // Handle clearing player ID when removed
      this.handleEvent('clear_player_id', (data) => {
        PlayerStorage.clearPlayerId(data.game_code);
      });

      // Show game not found toast if needed
      if (this.el.dataset.showGameNotFound === 'true') {
        Toast.show('Game not found. Please check the game code.', 'danger');
      }
    },
  },
};

// Register hooks with LiveSocket
let liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// Clean up any orphaned toasts on page load
document.addEventListener('DOMContentLoaded', () => {
  const existingToasts = document.querySelectorAll('.toast');
  existingToasts.forEach((toast) => toast.remove());
});

// Toast message system
const Toast = {
  show: (message, type = 'info', duration = 3000) => {
    // Remove any existing toasts
    const existingToasts = document.querySelectorAll('.toast');
    existingToasts.forEach((toast) => toast.remove());

    // Create toast element
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;

    const icon =
      type === 'success'
        ? '✓'
        : type === 'info'
        ? 'ℹ'
        : type === 'warning'
        ? '⚠'
        : '✕';

    toast.innerHTML = `
      <div class="toast-content">
        <span class="toast-icon">${icon}</span>
        <span class="toast-message">${message}</span>
      </div>
    `;

    // Add to page
    document.body.appendChild(toast);

    // Trigger animation
    setTimeout(() => toast.classList.add('show'), 10);

    // Auto remove
    setTimeout(() => {
      toast.classList.remove('show');
      setTimeout(() => toast.remove(), 300);
    }, duration);
  },
};

// Copy to clipboard functionality with toast messages
document.addEventListener('click', (e) => {
  if (e.target.matches("[phx-click='copy_code']")) {
    const gameCode = e.target.getAttribute('data-code');
    navigator.clipboard
      .writeText(gameCode)
      .then(() => {
        Toast.show('Game code copied to clipboard!', 'success');
      })
      .catch(() => {
        Toast.show('Failed to copy game code', 'danger');
      });
  }

  if (e.target.matches("[phx-click='copy_link']")) {
    const gameLink = e.target.getAttribute('data-link');
    navigator.clipboard
      .writeText(gameLink)
      .then(() => {
        Toast.show('Game link copied to clipboard!', 'success');
      })
      .catch(() => {
        Toast.show('Failed to copy game link', 'danger');
      });
  }
});

// Handle form submissions for game joining
document.addEventListener('submit', (e) => {
  if (e.target.matches('form[phx-submit="join_game"]')) {
    // Store the form data to check later if redirect happened
    const formData = new FormData(e.target);
    const gameCode = formData.get('game_code');

    // Set a timeout to check if redirect happened
    setTimeout(() => {
      // If we're still on the same page, the game wasn't found
      if (window.location.pathname === '/' && gameCode) {
        Toast.show('Game not found. Please check the game code.', 'danger');
      }
    }, 100);
  }
});
