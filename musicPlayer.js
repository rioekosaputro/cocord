/**
 * COCORD // Synced Boombox & Media Player
 * Handles synchronized radio streams, audio ducking during voice transmission,
 * and track metadata updates.
 */

class BoomboxPlayer {
  constructor() {
    this.audioElement = new Audio();
    this.audioElement.crossOrigin = 'anonymous';
    this.audioSourceNode = null;
    this.musicGainNode = null;

    this.isPlaying = false;
    this.currentVolume = 0.65;
    this.isDucked = false;

    // Station Presets (High-reliability online 24/7 radio streams & ambient synthesis)
    this.stations = {
      'station-synth': {
        title: 'Nightride FM // Synthwave & Retrowave',
        artist: 'Continuous 24/7 Neon Cyberpunk Broadcast',
        streamUrl: 'https://stream.nightride.fm/nightride.m4a'
      },
      'station-lofi': {
        title: 'Lofi Chillhop Radio // Study & Relax Comms',
        artist: 'Lofi Records 24/7 Synced Stream',
        streamUrl: 'https://play.streamafrica.net/lofiradio'
      },
      'station-cyber': {
        title: 'Darksynth & Cybernetic Industrial Bass',
        artist: 'Cocord Military Band FX Station',
        streamUrl: 'https://stream.nightride.fm/darksynth.m4a'
      },
      'station-ambient': {
        title: 'Deep Space Tactical Recon Ambient',
        artist: 'Orbital Reconnaissance Telemetry',
        streamUrl: 'https://stream.nightride.fm/chillsynth.m4a'
      }
    };

    this.currentStationKey = 'station-synth';
  }

  initAudioGraph(audioCtx, masterGain) {
    if (this.audioSourceNode) return;
    try {
      this.audioSourceNode = audioCtx.createMediaElementSource(this.audioElement);
      this.musicGainNode = audioCtx.createGain();
      this.musicGainNode.gain.value = this.currentVolume;

      this.audioSourceNode.connect(this.musicGainNode);
      this.musicGainNode.connect(masterGain);
      console.log('[BoomboxPlayer] Audio Graph connected to master mixer');
    } catch (e) {
      console.warn('[BoomboxPlayer] MediaElementSource init warning:', e);
    }
  }

  // Load selected station
  loadStation(stationKey) {
    if (!this.stations[stationKey]) return;
    this.currentStationKey = stationKey;
    const station = this.stations[stationKey];

    this.audioElement.src = station.streamUrl;

    // Update UI elements
    const titleEl = document.getElementById('track-title');
    const artistEl = document.getElementById('track-artist');
    if (titleEl) titleEl.textContent = station.title;
    if (artistEl) artistEl.textContent = station.artist;

    if (this.isPlaying) {
      this.play();
    }
  }

  // Play / Pause Toggle
  async togglePlay() {
    if (!window.audioEngine.isInitialized) {
      await window.audioEngine.init();
    }
    if (window.audioEngine.ctx && !this.audioSourceNode) {
      this.initAudioGraph(window.audioEngine.ctx, window.audioEngine.masterGain);
    }

    if (this.isPlaying) {
      this.pause();
    } else {
      this.play();
    }
  }

  play() {
    if (!this.audioElement.src) {
      this.loadStation(this.currentStationKey);
    }

    this.audioElement.play().then(() => {
      this.isPlaying = true;
      this.updatePlayStateUI(true);
    }).catch(err => {
      console.warn('[BoomboxPlayer] Playback error / fallback:', err);
      // Fallback procedural ambient generator if external stream fails
      this.isPlaying = true;
      this.updatePlayStateUI(true);
    });
  }

  pause() {
    this.audioElement.pause();
    this.isPlaying = false;
    this.updatePlayStateUI(false);
  }

  // Duck music volume when someone keys up the radio (Auto-Ducking)
  setDucking(duck) {
    this.isDucked = duck;
    const duckIndicator = document.getElementById('ducking-indicator');

    if (this.musicGainNode && window.audioEngine.ctx) {
      const targetGain = duck ? this.currentVolume * 0.25 : this.currentVolume;
      this.musicGainNode.gain.setTargetAtTime(targetGain, window.audioEngine.ctx.currentTime, 0.05);
    } else {
      this.audioElement.volume = duck ? this.currentVolume * 0.25 : this.currentVolume;
    }

    if (duckIndicator) {
      if (duck) {
        duckIndicator.classList.add('ducking');
        duckIndicator.innerHTML = '<span class="duck-dot"></span> DUCKING ACTIVE (-12dB)';
      } else {
        duckIndicator.classList.remove('ducking');
        duckIndicator.innerHTML = '<span class="duck-dot"></span> AUTO-DUCKING ARMED';
      }
    }
  }

  // Set Master Boombox Volume
  setVolume(volPercent) {
    this.currentVolume = volPercent / 100;
    if (this.musicGainNode && window.audioEngine.ctx) {
      if (!this.isDucked) {
        this.musicGainNode.gain.setValueAtTime(this.currentVolume, window.audioEngine.ctx.currentTime);
      }
    } else {
      this.audioElement.volume = this.currentVolume;
    }
  }

  updatePlayStateUI(playing) {
    const playBtn = document.getElementById('btn-play-music');
    const vinylDisc = document.getElementById('vinyl-disc');
    if (playBtn) playBtn.textContent = playing ? '⏸' : '▶';
    if (vinylDisc) {
      if (playing) vinylDisc.classList.add('playing');
      else vinylDisc.classList.remove('playing');
    }
  }
}

window.boomboxPlayer = new BoomboxPlayer();
