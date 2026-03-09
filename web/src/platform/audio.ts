import type { PlatformAudio, AudioDevice } from '@/platform/types';

type HTMLMediaElementWithSinkId = HTMLAudioElement & {
  setSinkId?: (sinkId: string) => Promise<void>;
};

const activePlayers: HTMLAudioElement[] = [];

function stopAllActivePlayers() {
  while (activePlayers.length > 0) {
    const player = activePlayers.pop();
    if (!player) {
      continue;
    }
    player.pause();
    player.src = '';
  }
}

export const webAudio: PlatformAudio = {
  isSystemAudioSupported(): boolean {
    return false; // System audio capture not supported in web
  },

  async startSystemAudioCapture(_maxDurationSecs: number): Promise<void> {
    throw new Error('System audio capture is only available in the desktop app.');
  },

  async stopSystemAudioCapture(): Promise<Blob> {
    throw new Error('System audio capture is only available in the desktop app.');
  },

  async listOutputDevices(): Promise<AudioDevice[]> {
    if (!navigator?.mediaDevices?.enumerateDevices) {
      return [];
    }

    try {
      // Ask once for media permission so browsers can expose output device labels.
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      stream.getTracks().forEach((track) => track.stop());
    } catch {
      // Continue without labels if permission was denied.
    }

    const devices = await navigator.mediaDevices.enumerateDevices();
    const outputDevices = devices.filter((device) => device.kind === 'audiooutput');

    return outputDevices.map((device, index) => ({
      id: device.deviceId || `audio-output-${index}`,
      name: device.label || `Audio output ${index + 1}`,
      is_default:
        device.deviceId === 'default' || outputDevices.length === 1 || index === 0,
    }));
  },

  async playToDevices(audioData: Uint8Array, deviceIds: string[]): Promise<void> {
    if (deviceIds.length === 0) {
      return;
    }

    const normalizedAudioData = new Uint8Array(audioData);
    const audioBlob = new Blob([normalizedAudioData.buffer], { type: 'audio/wav' });
    const sourceUrl = URL.createObjectURL(audioBlob);

    stopAllActivePlayers();

    const supportsSinkSelection =
      typeof (HTMLAudioElement.prototype as HTMLMediaElementWithSinkId).setSinkId === 'function';
    if (!supportsSinkSelection) {
      URL.revokeObjectURL(sourceUrl);
      throw new Error('Audio output device selection is not supported by this browser.');
    }

    const startTasks = deviceIds.map(async (deviceId) => {
      const player = new Audio(sourceUrl) as HTMLMediaElementWithSinkId;
      player.preload = 'auto';
      player.onended = () => {
        const index = activePlayers.indexOf(player);
        if (index >= 0) {
          activePlayers.splice(index, 1);
        }
      };
      activePlayers.push(player);

      await player.setSinkId?.(deviceId);
      await player.play();
    });

    try {
      await Promise.all(startTasks);
    } finally {
      URL.revokeObjectURL(sourceUrl);
    }
  },

  stopPlayback(): void {
    stopAllActivePlayers();
  },
};
