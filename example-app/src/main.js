import { CapacitorUpdater } from '@capgo/capacitor-updater';
import { Capacitor } from '@capacitor/core';
import './style.css';
import { Auto } from '@capgo/capacitor-auto';

const output = document.getElementById('plugin-output');
const templateTitleInput = document.getElementById('template-title');
const setTemplateButton = document.getElementById('set-template');
const availabilityButton = document.getElementById('check-availability');
const versionButton = document.getElementById('get-version');

const setOutput = (value) => {
  output.textContent = typeof value === 'string' ? value : JSON.stringify(value, null, 2);
};

Auto.addListener('connectionChanged', (event) => {
  setOutput({ event: 'connectionChanged', ...event });
});

Auto.addListener('carAction', (event) => {
  setOutput({ event: 'carAction', ...event });
});

setTemplateButton.addEventListener('click', async () => {
  try {
    await Auto.setRootTemplate({
      title: templateTitleInput.value,
      sections: [
        {
          header: 'Actions',
          items: [
            {
              id: 'primary-action',
              title: 'Primary action',
              subtitle: 'Tap this row on the car display',
              payload: { source: 'example-app' },
            },
          ],
        },
      ],
    });
    setOutput('Template sent to the car bridge.');
  } catch (error) {
    setOutput(`Error: ${error?.message ?? error}`);
  }
});

availabilityButton.addEventListener('click', async () => {
  try {
    const result = await Auto.isAvailable();
    setOutput(result);
  } catch (error) {
    setOutput(`Error: ${error?.message ?? error}`);
  }
});

versionButton.addEventListener('click', async () => {
  try {
    const result = await Auto.getPluginVersion();
    setOutput(result);
  } catch (error) {
    setOutput(`Error: ${error?.message ?? error}`);
  }
});

if (Capacitor.isNativePlatform()) {
  CapacitorUpdater.notifyAppReady().catch((error) => {
    console.error('Capgo notifyAppReady failed', error);
  });
}
