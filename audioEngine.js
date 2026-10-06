/**
 * FREQWAVE // Web Audio API DSP & Sound Effects Engine
 * Provides authentic radio walkie-talkie filtering, squelch bursts,
 * roger beeps, ambient static, and oscilloscope visualizers.
 */

class AudioEngine {
  constructor() {
    this.ctx = null;
    this.isInitialized = false;

    // Nodes
    this.masterGain = null;
    this.analyser = null;
    this.staticGain = null;
    this.staticSource = null;
    this.micStream = null;
    this.micSource = null;
    this.micGain = null;
    this.bandpassFilter = null;
    this.distortionNode = null;

    // DSP Modulation Toggles
    this.filterEnabled = true;
    this.rogerBeepEnabled = true;
    this.squelchBurstEnabled = true;
    this.staticEnabled = true;
    this.staticVolume = 0.12;
    this.micGainVal = 1.0;

    // Transmit State
    this.isTransmitting = false;
  }

  // Initialize Web Audio context upon first user interaction
  async init() {
    if (this.isInitialized) return;
    const AudioContextClass = window.AudioContext || window.webkitAudioContext;
    this.ctx = new AudioContextClass();

    if (this.ctx.state === 'suspended') {
      await this.ctx.resume();
    }

    // Master Output & Analyser for Scope
    this.masterGain = this.ctx.createGain();
    this.masterGain.gain.value = 1.0;

    this.analyser = this.ctx.createAnalyser();
    this.analyser.fftSize = 1024;
    this.analyser.smoothingTimeConstant = 0.85;

    this.masterGain.connect(this.analyser);
    this.analyser.connect(this.ctx.destination);

    // Build Ambient RF Static Generator
    this.initStaticNoise();

    this.isInitialized = true;
    console.log('[AudioEngine] Web Audio DSP Initialized');
  }

  // Build Procedural White Noise Static Loop
  initStaticNoise() {
    const bufferSize = 2 * this.ctx.sampleRate;
    const noiseBuffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const output = noiseBuffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      output[i] = Math.random() * 2 - 1;
    }

    this.staticSource = this.ctx.createBufferSource();
    this.staticSource.buffer = noiseBuffer;
    this.staticSource.loop = true;

    // Bandpass the static so it sounds like analog atmospheric radio hiss
    const staticFilter = this.ctx.createBiquadFilter();
    staticFilter.type = 'bandpass';
    staticFilter.frequency.value = 1200;
    staticFilter.Q.value = 1.5;

    this.staticGain = this.ctx.createGain();
    this.staticGain.gain.value = this.staticEnabled ? this.staticVolume * 0.25 : 0.0;

    this.staticSource.connect(staticFilter);
    staticFilter.connect(this.staticGain);
    this.staticGain.connect(this.masterGain);

    this.staticSource.start(0);
  }

  // Set Static Noise Volume
  setStaticVolume(val) {
    this.staticVolume = val;
    if (this.staticGain && this.ctx) {
      this.staticGain.gain.setTargetAtTime(
        this.staticEnabled ? this.staticVolume * 0.25 : 0.0,
        this.ctx.currentTime,
        0.05
      );
    }
  }

  // Set Static Enabled
  setStaticEnabled(enabled) {
    this.staticEnabled = enabled;
    this.setStaticVolume(this.staticVolume);
  }

  // Create subtle overdrive curve for gritty tactical radio harmonics
  makeDistortionCurve(amount = 20) {
    const k = typeof amount === 'number' ? amount : 50;
    const n_samples = 44100;
    const curve = new Float32Array(n_samples);
    const deg = Math.PI / 180;
    for (let i = 0; i < n_samples; ++i) {
      const x = (i * 2) / n_samples - 1;
      curve[i] = ((3 + k) * x * 20 * deg) / (Math.PI + k * Math.abs(x));
    }
    return curve;
  }

  // Connect Microphone Input with Radio Filter Chain
  async setupMicrophone() {
    if (this.micSource) return;
    try {
      this.micStream = await navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: true,
          noiseSuppression: false, // We supply our own gritty tactical vibe!
          autoGainControl: true
        },
        video: false
      });

      this.micSource = this.ctx.createMediaStreamSource(this.micStream);

      // Mic Gain
      this.micGain = this.ctx.createGain();
      this.micGain.gain.value = 0.0; // Muted until PTT is held

      // Tactical Bandpass Filter (Highpass 350Hz + Lowpass 3400Hz)
      const highpass = this.ctx.createBiquadFilter();
      highpass.type = 'highpass';
      highpass.frequency.value = 350;

      const lowpass = this.ctx.createBiquadFilter();
      lowpass.type = 'lowpass';
      lowpass.frequency.value = 3400;

      // Distortion/Saturation
      this.distortionNode = this.ctx.createWaveShaper();
      this.distortionNode.curve = this.makeDistortionCurve(15);
      this.distortionNode.oversample = '2x';

      // Connect Chain: Mic -> Gain -> Highpass -> Lowpass -> Distortion -> Master
      this.micSource.connect(highpass);
      highpass.connect(lowpass);
      lowpass.connect(this.distortionNode);
      this.distortionNode.connect(this.micGain);
      this.micGain.connect(this.masterGain);

      console.log('[AudioEngine] Microphone and DSP filter chain attached');
    } catch (err) {
      console.warn('[AudioEngine] Mic permission not granted or device missing:', err);
    }
  }

  // Play Squelch Burst (Carrier Keyup / Tail Noise)
  playSquelchBurst(isKeyup = false) {
    if (!this.squelchBurstEnabled || !this.ctx) return;

    const duration = isKeyup ? 0.04 : 0.09;
    const now = this.ctx.currentTime;

    const bufferSize = this.ctx.sampleRate * duration;
    const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = Math.random() * 2 - 1;
    }

    const noise = this.ctx.createBufferSource();
    noise.buffer = buffer;

    const filter = this.ctx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.value = isKeyup ? 1800 : 2200;
    filter.Q.value = 2.0;

    const gain = this.ctx.createGain();
    gain.gain.setValueAtTime(0.35, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + duration);

    noise.connect(filter);
    filter.connect(gain);
    gain.connect(this.masterGain);

    noise.start(now);
  }

  // Play Roger Beep (Signature dual-chirp end of transmission sound)
  playRogerBeep() {
    if (!this.rogerBeepEnabled || !this.ctx) return;

    const now = this.ctx.currentTime;
    
    // Tone 1: 1200 Hz
    const osc1 = this.ctx.createOscillator();
    const gain1 = this.ctx.createGain();
    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(1200, now);
    gain1.gain.setValueAtTime(0.2, now);
    gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.07);
    osc1.connect(gain1);
    gain1.connect(this.masterGain);
    osc1.start(now);
    osc1.stop(now + 0.07);

    // Tone 2: 950 Hz (plays immediately after tone 1)
    const osc2 = this.ctx.createOscillator();
    const gain2 = this.ctx.createGain();
    osc2.type = 'sine';
    osc2.frequency.setValueAtTime(950, now + 0.075);
    gain2.gain.setValueAtTime(0.25, now + 0.075);
    gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.16);
    osc2.connect(gain2);
    gain2.connect(this.masterGain);
    osc2.start(now + 0.075);
    osc2.stop(now + 0.16);
  }

  // Start Transmission (PTT Down)
  startTransmitting() {
    if (this.isTransmitting) return;
    this.isTransmitting = true;

    if (!this.isInitialized) {
      this.init();
    }
    if (!this.micSource) {
      this.setupMicrophone();
    }

    // Play initial tactical mic click / keyup squelch
    this.playSquelchBurst(true);

    // Unmute mic gain
    if (this.micGain && this.ctx) {
      this.micGain.gain.setTargetAtTime(this.micGainVal, this.ctx.currentTime, 0.02);
    }
  }

  // Stop Transmission (PTT Up)
  stopTransmitting() {
    if (!this.isTransmitting) return;
    this.isTransmitting = false;

    // Mute mic gain
    if (this.micGain && this.ctx) {
      this.micGain.gain.setTargetAtTime(0.0, this.ctx.currentTime, 0.02);
    }

    // Play roger beep followed by squelch tail burst
    this.playRogerBeep();
    setTimeout(() => {
      this.playSquelchBurst(false);
    }, 120);
  }

  // Soundboard Trigger Synthesizers
  playSoundboard(soundName) {
    if (!this.ctx) this.init();
    const now = this.ctx.currentTime;

    switch (soundName) {
      case 'roger':
        this.playRogerBeep();
        setTimeout(() => this.playSquelchBurst(false), 150);
        break;

      case 'airhorn': {
        const freqs = [466.16, 466.16, 622.25, 740.0, 932.33];
        freqs.forEach((f, idx) => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'sawtooth';
          osc.frequency.setValueAtTime(f + (idx * 2), now);
          gain.gain.setValueAtTime(0.12, now);
          gain.gain.exponentialRampToValueAtTime(0.001, now + 0.7);
          osc.connect(gain);
          gain.connect(this.masterGain);
          osc.start(now);
          osc.stop(now + 0.7);
        });
        break;
      }

      case 'siren': {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(500, now);
        osc.frequency.linearRampToValueAtTime(1100, now + 0.3);
        osc.frequency.linearRampToValueAtTime(500, now + 0.6);
        osc.frequency.linearRampToValueAtTime(1100, now + 0.9);
        osc.frequency.linearRampToValueAtTime(500, now + 1.2);
        gain.gain.setValueAtTime(0.2, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 1.3);
        osc.connect(gain);
        gain.connect(this.masterGain);
        osc.start(now);
        osc.stop(now + 1.3);
        break;
      }

      case 'morse': {
        // Play SOS in Morse: ... --- ...
        const morsePattern = [
          { freq: 800, dur: 0.08, delay: 0 },
          { freq: 800, dur: 0.08, delay: 0.12 },
          { freq: 800, dur: 0.08, delay: 0.24 },
          { freq: 800, dur: 0.22, delay: 0.40 },
          { freq: 800, dur: 0.22, delay: 0.68 },
          { freq: 800, dur: 0.22, delay: 0.96 },
          { freq: 800, dur: 0.08, delay: 1.24 },
          { freq: 800, dur: 0.08, delay: 1.36 },
          { freq: 800, dur: 0.08, delay: 1.48 }
        ];
        morsePattern.forEach(m => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(m.freq, now + m.delay);
          gain.gain.setValueAtTime(0.2, now + m.delay);
          gain.gain.exponentialRampToValueAtTime(0.001, now + m.delay + m.dur);
          osc.connect(gain);
          gain.connect(this.masterGain);
          osc.start(now + m.delay);
          osc.stop(now + m.delay + m.dur);
        });
        break;
      }

      case 'target': {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(1800, now);
        osc.frequency.exponentialRampToValueAtTime(3200, now + 0.15);
        osc.frequency.setValueAtTime(3200, now + 0.18);
        gain.gain.setValueAtTime(0.25, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.35);
        osc.connect(gain);
        gain.connect(this.masterGain);
        osc.start(now);
        osc.stop(now + 0.35);
        break;
      }

      case 'glitch': {
        const bufferSize = this.ctx.sampleRate * 0.3;
        const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) {
          data[i] = (Math.random() * 2 - 1) * (i % 20 < 10 ? 1 : -0.5);
        }
        const noise = this.ctx.createBufferSource();
        noise.buffer = buffer;
        const gain = this.ctx.createGain();
        gain.gain.setValueAtTime(0.3, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.3);
        noise.connect(gain);
        gain.connect(this.masterGain);
        noise.start(now);
        break;
      }
    }
  }

  // Draw Live CRT Oscilloscope on Canvas
  drawOscilloscope(canvas) {
    if (!canvas) return;
    const canvasCtx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;

    const dataArray = new Uint8Array(this.analyser ? this.analyser.frequencyBinCount : 512);

    const render = () => {
      requestAnimationFrame(render);

      if (this.analyser) {
        this.analyser.getByteTimeDomainData(dataArray);
      } else {
        // Idle ambient line with slight noise
        for (let i = 0; i < dataArray.length; i++) {
          dataArray[i] = 128 + (Math.random() * 4 - 2);
        }
      }

      // Calculate average amplitude for VU Meter
      let sum = 0;
      for (let i = 0; i < dataArray.length; i++) {
        sum += Math.abs(dataArray[i] - 128);
      }
      const average = sum / dataArray.length;
      const vuPercent = Math.min(100, Math.max(5, (average / 30) * 100));
      const vuFill = document.getElementById('vu-fill');
      if (vuFill) vuFill.style.width = `${vuPercent}%`;

      // Canvas clear with clean modern fade
      canvasCtx.fillStyle = '#0d121c';
      canvasCtx.fillRect(0, 0, width, height);

      // Draw Clean Modern Waveform
      canvasCtx.lineWidth = this.isTransmitting ? 2.5 : 1.8;
      canvasCtx.strokeStyle = this.isTransmitting ? '#ef4444' : '#3b82f6';
      canvasCtx.shadowBlur = this.isTransmitting ? 10 : 0;
      canvasCtx.shadowColor = this.isTransmitting ? 'rgba(239, 68, 68, 0.5)' : 'transparent';

      canvasCtx.beginPath();
      const sliceWidth = (width * 1.0) / dataArray.length;
      let x = 0;

      for (let i = 0; i < dataArray.length; i++) {
        const v = dataArray[i] / 128.0;
        const y = (v * height) / 2;

        if (i === 0) {
          canvasCtx.moveTo(x, y);
        } else {
          canvasCtx.lineTo(x, y);
        }
        x += sliceWidth;
      }

      canvasCtx.lineTo(width, height / 2);
      canvasCtx.stroke();
    };

    render();
  }
}

// Attach instance to window
window.audioEngine = new AudioEngine();
