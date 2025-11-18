(function () {
  const REQUIRED_KEY = 'wizard_php83_extensions';

  function getSelection() {
    try {
      return JSON.parse(WizardStorage.get(REQUIRED_KEY) || '{}');
    } catch (err) {
      return {};
    }
  }

  function saveSelection(state) {
    WizardStorage.set(REQUIRED_KEY, JSON.stringify(state));
  }

  function ensureDependencies(state, manifest) {
    manifest.forEach(option => {
      if (state[option.id]) {
        option.dependencies.forEach(dep => {
          state[dep] = true;
        });
      }
    });
    return state;
  }

  function blockConflicts(state, manifest) {
    manifest.forEach(option => {
      if (!state[option.id]) {
        return;
      }
      option.conflicts.forEach(conflict => {
        if (state[conflict]) {
          Wizard.showMessage('Conflict', `${option.name} conflicts with ${conflict}.`);
          state[conflict] = false;
        }
      });
    });
    return state;
  }

  function calculateFootprint(state, manifest) {
    return manifest.reduce((acc, option) => {
      if (state[option.id]) {
        acc += option.diskFootprintMb || 0;
      }
      return acc;
    }, 0);
  }

  function showRestartSummary(state, manifest) {
    const restarts = new Set();
    manifest.forEach(option => {
      if (state[option.id]) {
        restarts.add(option.restartRequirement || 'php-fpm');
      }
    });
    Wizard.showMessage('Restarts Required', Array.from(restarts).join(', '));
  }

  window.extensionSelectionValidate = function (manifest) {
    let state = getSelection();
    state = ensureDependencies(state, manifest);
    state = blockConflicts(state, manifest);
    saveSelection(state);
    const footprint = calculateFootprint(state, manifest);
    if (footprint > 500) {
      Wizard.showMessage('Disk Usage Warning', `Extensions require ${footprint}MB. Ensure space is available.`);
    }
    showRestartSummary(state, manifest);
    return true;
  };
})();
