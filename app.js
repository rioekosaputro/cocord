/**
 * FREQWAVE // Main App Coordinator & Event Controller
 * Connects UI interactions, PTT hotkeys, Frequency dialers,
 * Scanner mode, and Audio DSP pipeline.
 */

document.addEventListener('DOMContentLoaded', () => {
  console.log('[FreqWave] Initializing Tactical Radio System...');

  // State
  let currentFreq = 144.800;
  let isPTTActive = false;
  let isScanning = false;
  let scanInterval = null;
  let openMicEnabled = false;

  // DOM Elements
  const hudFreqVal = document.getElementById('hud-freq-val');
  const hudSubVal = document.getElementById('hud-sub-val');
  const manualFreqInput = document.getElementById('manual-freq-input');
  const freqSlider = document.getElementById('freq-slider');
  const callsignInput = document.getElementById('callsign-input');
  const localPeerName = document.getElementById('local-peer-name');
  const pttButton = document.getElementById('btn-ptt');
  const pttText = document.getElementById('ptt-text');
  const txStatusBadge = document.getElementById('tx-status-badge');
  const scopeCanvas = document.getElementById('scope-canvas');

  // DSP Toggles
  const toggleRadioFilter = document.getElementById('toggle-radio-filter');
  const toggleRogerBeep = document.getElementById('toggle-roger-beep');
  const toggleSquelchBurst = document.getElementById('toggle-squelch-burst');
  const toggleStatic = document.getElementById('toggle-static');
  const sliderStaticVol = document.getElementById('slider-static-vol');
  const sliderMicGain = document.getElementById('slider-mic-gain');
  const staticVolVal = document.getElementById('static-vol-val');
  const micGainVal = document.getElementById('mic-gain-val');

  // Music & Boombox
  const btnPlayMusic = document.getElementById('btn-play-music');
  const stationSelect = document.getElementById('music-station-select');
  const musicVolSlider = document.getElementById('music-volume-slider');

  // Chat & Scanner
  const chatForm = document.getElementById('chat-form');
  const chatInput = document.getElementById('chat-input');
  const btnScan = document.getElementById('btn-scan');
  const btnShareFreq = document.getElementById('btn-share-freq');
  const btnOpenMic = document.getElementById('btn-open-mic');
  const presetCards = document.querySelectorAll('.preset-card');
  const soundPads = document.querySelectorAll('.sound-pad');

  // Initialize Canvas
  if (scopeCanvas) {
    scopeCanvas.width = scopeCanvas.parentElement.clientWidth || 800;
    scopeCanvas.height = 140;
    window.audioEngine.drawOscilloscope(scopeCanvas);
  }

  // Initialize Chat & Peer
  window.chatEngine.init(currentFreq.toFixed(3), callsignInput.value);

  // ---------------------------------------------------------------------------
  // FREQUENCY TUNING LOGIC
  // ---------------------------------------------------------------------------
  function setFrequency(freq, presetName = null) {
    currentFreq = Math.max(88.0, Math.min(999.0, parseFloat(freq)));
    const freqStr = currentFreq.toFixed(3);

    hudFreqVal.textContent = freqStr;
    manualFreqInput.value = currentFreq.toFixed(2);
    freqSlider.value = currentFreq;

    if (presetName) {
      hudSubVal.textContent = `${presetName.toUpperCase()} // SQUAD SECURE`;
    } else {
      hudSubVal.textContent = `MANUAL TUNE // RF CHANNEL ${Math.floor(currentFreq * 10) % 100}`;
    }

    // Update Presets highlight
    presetCards.forEach(card => {
      if (Math.abs(parseFloat(card.dataset.freq) - currentFreq) < 0.05) {
        card.classList.add('active');
      } else {
        card.classList.remove('active');
      }
    });

    // Notify Chat & Audio
    window.chatEngine.switchFrequency(freqStr);
    if (window.audioEngine.isInitialized) {
      window.audioEngine.playSquelchBurst(false);
    }
  }

  // Presets click
  presetCards.forEach(card => {
    card.addEventListener('click', () => {
      const f = parseFloat(card.dataset.freq);
      const name = card.dataset.name;
      setFrequency(f, name);
    });
  });

  // Manual Tuning Buttons & Sliders
  document.getElementById('btn-freq-up').addEventListener('click', () => {
    setFrequency(currentFreq + 0.05);
  });
  document.getElementById('btn-freq-down').addEventListener('click', () => {
    setFrequency(currentFreq - 0.05);
  });
  manualFreqInput.addEventListener('change', (e) => {
    setFrequency(e.target.value);
  });
  freqSlider.addEventListener('input', (e) => {
    setFrequency(e.target.value);
  });

  // Frequency Scanner Mode
  btnScan.addEventListener('click', () => {
    if (isScanning) {
      clearInterval(scanInterval);
      isScanning = false;
      btnScan.textContent = 'SCANNER';
      btnScan.classList.remove('btn-highlight');
    } else {
      isScanning = true;
      btnScan.textContent = 'SCANNING...';
      btnScan.classList.add('btn-highlight');

      const scanFreqs = [88.5, 98.5, 104.2, 121.5, 144.8, 433.92, 446.0];
      let scanIdx = 0;

      scanInterval = setInterval(() => {
        setFrequency(scanFreqs[scanIdx]);
        scanIdx = (scanIdx + 1) % scanFreqs.length;
      }, 1500);
    }
  });

  // ---------------------------------------------------------------------------
  // PUSH-TO-TALK (PTT) ENGINE & HOTKEYS
  // ---------------------------------------------------------------------------
  function startPTT() {
    if (isPTTActive) return;
    isPTTActive = true;

    pttButton.classList.add('active');
    pttText.textContent = 'TRANSMITTING...';
    txStatusBadge.className = 'badge badge-red transmitting';
    txStatusBadge.textContent = 'TX (BROADCASTING)';

    // Duck boombox volume
    window.boomboxPlayer.setDucking(true);

    // Audio Engine transmit
    window.audioEngine.startTransmitting();

    // Visual feedback for local peer item
    const localUser = document.querySelector('.local-user');
    if (localUser) localUser.classList.add('transmitting');
  }

  function stopPTT() {
    if (!isPTTActive || openMicEnabled) return;
    isPTTActive = false;

    pttButton.classList.remove('active');
    pttText.textContent = 'PUSH TO TALK';
    txStatusBadge.className = 'badge badge-red';
    txStatusBadge.textContent = 'RX (STANDBY)';

    // Restore boombox volume
    window.boomboxPlayer.setDucking(false);

    // Audio Engine stop
    window.audioEngine.stopTransmitting();

    // Visual feedback
    const localUser = document.querySelector('.local-user');
    if (localUser) localUser.classList.remove('transmitting');
  }

  // Mouse & Touch events for PTT Button
  pttButton.addEventListener('mousedown', startPTT);
  window.addEventListener('mouseup', stopPTT);
  pttButton.addEventListener('touchstart', (e) => {
    e.preventDefault();
    startPTT();
  });
  window.addEventListener('touchend', stopPTT);

  // Global Spacebar PTT Hotkey (Ignore if typing in chat or input)
  window.addEventListener('keydown', (e) => {
    if (e.code === 'Space' && !['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) {
      e.preventDefault();
      startPTT();
    }
  });

  window.addEventListener('keyup', (e) => {
    if (e.code === 'Space' && !['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) {
      e.preventDefault();
      stopPTT();
    }
  });

  // Open Mic Toggle
  btnOpenMic.addEventListener('click', () => {
    openMicEnabled = !openMicEnabled;
    if (openMicEnabled) {
      btnOpenMic.textContent = 'OPEN MIC: ON';
      btnOpenMic.classList.add('btn-highlight');
      startPTT();
    } else {
      btnOpenMic.textContent = 'OPEN MIC: OFF';
      btnOpenMic.classList.remove('btn-highlight');
      stopPTT();
    }
  });

  // ---------------------------------------------------------------------------
  // DSP MODULATION CONTROLS
  // ---------------------------------------------------------------------------
  toggleRadioFilter.addEventListener('change', (e) => {
    window.audioEngine.filterEnabled = e.target.checked;
  });
  toggleRogerBeep.addEventListener('change', (e) => {
    window.audioEngine.rogerBeepEnabled = e.target.checked;
  });
  toggleSquelchBurst.addEventListener('change', (e) => {
    window.audioEngine.squelchBurstEnabled = e.target.checked;
  });
  toggleStatic.addEventListener('change', (e) => {
    window.audioEngine.setStaticEnabled(e.target.checked);
  });
  sliderStaticVol.addEventListener('input', (e) => {
    const val = parseInt(e.target.value);
    staticVolVal.textContent = `${val}%`;
    window.audioEngine.setStaticVolume(val / 100);
  });
  sliderMicGain.addEventListener('input', (e) => {
    const val = parseInt(e.target.value);
    micGainVal.textContent = `${val}%`;
    window.audioEngine.micGainVal = val / 100;
  });

  // ---------------------------------------------------------------------------
  // BOOMBOX / MUSIC CONTROLS
  // ---------------------------------------------------------------------------
  btnPlayMusic.addEventListener('click', () => {
    window.boomboxPlayer.togglePlay();
  });

  stationSelect.addEventListener('change', (e) => {
    window.boomboxPlayer.loadStation(e.target.value);
  });

  musicVolSlider.addEventListener('input', (e) => {
    window.boomboxPlayer.setVolume(parseInt(e.target.value));
  });

  document.getElementById('btn-next-track').addEventListener('click', () => {
    const opts = stationSelect.options;
    stationSelect.selectedIndex = (stationSelect.selectedIndex + 1) % opts.length;
    window.boomboxPlayer.loadStation(stationSelect.value);
  });

  document.getElementById('btn-prev-track').addEventListener('click', () => {
    const opts = stationSelect.options;
    stationSelect.selectedIndex = (stationSelect.selectedIndex - 1 + opts.length) % opts.length;
    window.boomboxPlayer.loadStation(stationSelect.value);
  });

  // ---------------------------------------------------------------------------
  // SOUNDBOARD TRIGGER BUTTONS
  // ---------------------------------------------------------------------------
  soundPads.forEach(pad => {
    pad.addEventListener('click', () => {
      const sound = pad.dataset.sound;
      window.audioEngine.playSoundboard(sound);
      window.chatEngine.addSystemMessage(`🔊 Soundboard drop: ${pad.textContent.trim()}`);
    });
  });

  // ---------------------------------------------------------------------------
  // CHAT & IDENTITY
  // ---------------------------------------------------------------------------
  callsignInput.addEventListener('change', (e) => {
    const newName = e.target.value.toUpperCase() || 'BRAVO-06';
    e.target.value = newName;
    window.chatEngine.callsign = newName;
    if (localPeerName) localPeerName.textContent = `${newName} (You)`;
    window.chatEngine.addSystemMessage(`🏷️ Callsign updated to ${newName}`);
  });

  chatForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const text = chatInput.value;
    if (text) {
      window.chatEngine.sendMessage(text);
      chatInput.value = '';
    }
  });

  // Master Mute Audio Toggle
  const btnMuteAll = document.getElementById('btn-mute-all');
  let isMuted = false;
  if (btnMuteAll) {
    btnMuteAll.addEventListener('click', () => {
      isMuted = !isMuted;
      if (window.audioEngine.masterGain && window.audioEngine.ctx) {
        window.audioEngine.masterGain.gain.setValueAtTime(isMuted ? 0.0 : 1.0, window.audioEngine.ctx.currentTime);
      }
      btnMuteAll.textContent = isMuted ? 'UNMUTE AUDIO' : 'MUTE AUDIO';
      btnMuteAll.classList.toggle('btn-highlight', isMuted);
    });
  }

  // Share Frequency Link
  btnShareFreq.addEventListener('click', () => {
    const url = `${window.location.origin}${window.location.pathname}?freq=${currentFreq.toFixed(3)}`;
    navigator.clipboard.writeText(url).then(() => {
      window.chatEngine.addSystemMessage(`📋 Frequency link copied: ${url}`);
      btnShareFreq.textContent = 'COPIED! ✅';
      setTimeout(() => {
        btnShareFreq.textContent = 'SHARE FREQUENCY 🔗';
      }, 2000);
    }).catch(() => {
      window.chatEngine.addSystemMessage(`📡 Frequency is ${currentFreq.toFixed(3)} MHz`);
    });
  });

  // Check URL query for shared frequency
  const urlParams = new URLSearchParams(window.location.search);
  const sharedFreq = urlParams.get('freq');
  if (sharedFreq) {
    setFrequency(parseFloat(sharedFreq));
  }
});
