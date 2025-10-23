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
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' });
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

// Copy to clipboard functionality
document.addEventListener('click', (e) => {
  if (e.target.matches("[phx-click='copy_code']")) {
    const gameCode = e.target.getAttribute('data-code');
    navigator.clipboard.writeText(gameCode).then(() => {
      // Flash message will be handled by LiveView
    });
  }

  if (e.target.matches("[phx-click='copy_link']")) {
    const gameLink = e.target.getAttribute('data-link');
    navigator.clipboard.writeText(gameLink).then(() => {
      // Flash message will be handled by LiveView
    });
  }
});
