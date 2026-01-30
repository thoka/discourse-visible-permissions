import { ajax } from "discourse/lib/ajax";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

function renderRawRights(node, data) {
  const pre = document.createElement("pre");
  pre.classList.add("discourse-visible-rights-raw");
  pre.textContent = JSON.stringify(data, null, 2);
  node.textContent = "";
  node.appendChild(pre);
}

async function loadRights(node) {
  const categoryId = node.dataset.category;

  if (!categoryId) {
    node.textContent = i18n("discourse_visible_rights.missing_category");
    return;
  }

  node.textContent = i18n("discourse_visible_rights.loading");

  try {
    const data = await ajax(`/c/${categoryId}/visible-rights.json`);
    renderRawRights(node, data);
  } catch {
    node.textContent = i18n("discourse_visible_rights.load_error");
  }
}

function decorateVisibleRights(elem) {
  const nodes = elem.querySelectorAll("span.discourse-visible-rights");

  nodes.forEach((node) => {
    if (node.dataset.visibleRightsLoaded === "true") {
      return;
    }

    node.dataset.visibleRightsLoaded = "true";
    loadRights(node);
  });
}

export default {
  name: "discourse-visible-rights",
  initialize() {
    withPluginApi((api) => {
      const siteSettings = api.container.lookup("service:site-settings");

      if (!siteSettings.discourse_visible_rights_enabled) {
        return;
      }

      api.decorateCookedElement(decorateVisibleRights, {
        id: "discourse-visible-rights",
      });
    });
  },
};
