/**
 * COCORD // Tactical Frequency Chat & P2P WebRTC Room Hub
 * Handles real-time text chat, callsigns, P2P WebRTC audio mesh on frequencies,
 * and ambient radio comms chatter.
 */

class ChatEngine {
  constructor() {
    this.currentFrequency = '144.800';
    this.callsign = 'BRAVO-06';
    this.peer = null;
    this.peerConnections = [];
    this.activeCalls = [];

    // Ambient tactical radio chatter messages
    this.ambientRadioLog = [
      { callsign: 'VIPER-2', text: 'All units, grid 4 is secure. Moving to waypoint Charlie.', color: 'viper' },
      { callsign: 'GHOST-9', text: 'Visual on supply drop. Radio telemetry synced at 99%.', color: 'ghost' },
      { callsign: 'RADAR-HQ', text: 'Atmospheric conditions clear. Squelch tone test: 1-2-3 roger.', color: 'amber' },
      { callsign: 'OVERLORD', text: 'Encrypted channel locked. Standby for squad frequency sweep.', color: 'red' },
      { callsign: 'ECHO-4', text: 'Boombox stream sounds crisp on 144.8 MHz. Roger that.', color: 'cyan' }
    ];

    this.ambientTimer = null;
  }

  init(freq, callsign) {
    this.currentFrequency = freq;
    this.callsign = callsign;

    this.initPeerMesh();
    this.startAmbientChatter();
  }

  // Initialize P2P WebRTC via PeerJS
  initPeerMesh() {
    try {
      const sanitizedFreq = this.currentFrequency.replace('.', '_');
      const randomSuffix = Math.floor(Math.random() * 10000);
      const peerId = `cocord_${sanitizedFreq}_${randomSuffix}`;

      if (window.Peer) {
        this.peer = new window.Peer(peerId, {
          debug: 1
        });

        this.peer.on('open', (id) => {
          console.log('[ChatEngine] Connected to WebRTC P2P Mesh with ID:', id);
          const netStatus = document.getElementById('net-status');
          if (netStatus) {
            netStatus.innerHTML = '<span class="status-dot online"></span><span class="status-text">MESH ONLINE (' + this.currentFrequency + ' MHz)</span>';
          }
        });

        // Incoming audio call from peer on same frequency
        this.peer.on('call', (call) => {
          console.log('[ChatEngine] Incoming audio stream from peer:', call.peer);
          if (window.audioEngine.micStream) {
            call.answer(window.audioEngine.micStream);
          } else {
            call.answer();
          }

          call.on('stream', (remoteStream) => {
            this.handleRemoteAudioStream(remoteStream);
          });
        });

        // Incoming data connection for real-time text & soundboard drops
        this.peer.on('connection', (conn) => {
          this.setupDataConnection(conn);
        });
      }
    } catch (e) {
      console.warn('[ChatEngine] PeerJS initialization fallback:', e);
    }
  }

  setupDataConnection(conn) {
    conn.on('data', (data) => {
      if (data.type === 'chat') {
        this.addMessage(data.callsign, data.text, 'remote');
      } else if (data.type === 'soundboard') {
        window.audioEngine.playSoundboard(data.sound);
        this.addSystemMessage(`🔊 ${data.callsign} triggered sound drop: ${data.sound.toUpperCase()}`);
      } else if (data.type === 'tx_start') {
        this.handlePeerTransmission(data.callsign, true);
      } else if (data.type === 'tx_stop') {
        this.handlePeerTransmission(data.callsign, false);
      }
    });
  }

  handleRemoteAudioStream(stream) {
    const audio = new Audio();
    audio.srcObject = stream;
    audio.play();

    if (window.audioEngine.ctx) {
      const source = window.audioEngine.ctx.createMediaStreamSource(stream);
      source.connect(window.audioEngine.masterGain);
    }
  }

  handlePeerTransmission(callsign, isTransmitting) {
    if (window.boomboxPlayer) {
      window.boomboxPlayer.setDucking(isTransmitting);
    }

    const peerItems = document.querySelectorAll('.peer-item');
    peerItems.forEach(item => {
      const name = item.querySelector('.peer-name');
      if (name && name.textContent.includes(callsign)) {
        if (isTransmitting) item.classList.add('transmitting');
        else item.classList.remove('transmitting');
      }
    });

    if (isTransmitting) {
      window.audioEngine.playSquelchBurst(true);
    } else {
      window.audioEngine.playRogerBeep();
      setTimeout(() => window.audioEngine.playSquelchBurst(false), 120);
    }
  }

  // Switch Frequency Room
  switchFrequency(newFreq) {
    this.currentFrequency = newFreq;
    const tag = document.getElementById('chat-freq-tag');
    if (tag) tag.textContent = `#${newFreq}`;

    this.addSystemMessage(`📡 Switched receiver to frequency ${newFreq} MHz.`);

    // Re-init P2P peer mesh for new frequency
    if (this.peer) {
      this.peer.destroy();
    }
    this.initPeerMesh();
  }

  // Send Chat Message
  sendMessage(text) {
    if (!text || !text.trim()) return;
    const trimmed = text.trim();
    this.addMessage(this.callsign, trimmed, 'local');

    // Broadcast over data connections if available
    this.peerConnections.forEach(conn => {
      if (conn.open) {
        conn.send({
          type: 'chat',
          callsign: this.callsign,
          text: trimmed,
          freq: this.currentFrequency
        });
      }
    });
  }

  // Render text message in feed
  addMessage(sender, text, type = 'remote') {
    const chatContainer = document.getElementById('chat-messages');
    if (!chatContainer) return;

    const timeStr = new Date().toTimeString().substring(0, 5);
    const msgDiv = document.createElement('div');
    msgDiv.className = `chat-msg ${type}`;

    const colorClass = type === 'local' ? 'local' : (sender.toLowerCase().includes('viper') ? 'viper' : 'ghost');

    msgDiv.innerHTML = `
      <div class="msg-header">
        <span class="callsign ${colorClass}">${sender}</span>
        <span class="time">${timeStr}</span>
      </div>
      <div class="msg-body">${this.escapeHTML(text)}</div>
    `;

    chatContainer.appendChild(msgDiv);
    chatContainer.scrollTop = chatContainer.scrollHeight;
  }

  // Render system status notification
  addSystemMessage(text) {
    const chatContainer = document.getElementById('chat-messages');
    if (!chatContainer) return;

    const timeStr = new Date().toTimeString().substring(0, 5);
    const msgDiv = document.createElement('div');
    msgDiv.className = 'chat-msg system';

    msgDiv.innerHTML = `
      <span class="time">${timeStr}</span>
      <span class="body">${this.escapeHTML(text)}</span>
    `;

    chatContainer.appendChild(msgDiv);
    chatContainer.scrollTop = chatContainer.scrollHeight;
  }

  // Periodic ambient comms to make frequencies feel buzzing and tactical
  startAmbientChatter() {
    if (this.ambientTimer) clearInterval(this.ambientTimer);

    this.ambientTimer = setInterval(() => {
      if (Math.random() < 0.6) {
        const item = this.ambientRadioLog[Math.floor(Math.random() * this.ambientRadioLog.length)];
        this.addMessage(item.callsign, item.text, 'remote');

        // Play subtle squelch click
        if (window.audioEngine && window.audioEngine.isInitialized) {
          window.audioEngine.playSquelchBurst(true);
        }
      }
    }, 28000); // every 28s
  }

  escapeHTML(str) {
    const p = document.createElement('p');
    p.textContent = str;
    return p.innerHTML;
  }
}

window.chatEngine = new ChatEngine();
