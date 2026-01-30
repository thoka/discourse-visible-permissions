import { ajax } from "discourse/lib/ajax";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

function renderRawPermissions(node, data) {
  const pre = document.createElement("pre");
  pre.classList.add("discourse-visible-permissions-raw");
  pre.textContent = JSON.stringify(data, null, 2);
  node.textContent = "";
  node.appendChild(pre);
}

async function loadPermissions(node) {
  const categoryId = node.dataset.category;

  if (!categoryId) {
    node.textContent = i18n("discourse_visible_permissions.missing_category");
    return;
  }

  node.textContent = i18n("discourse_visible_permissions.loading");

  try {
    const data = await ajax(`/c/${categoryId}/permissions.json`);
    renderRawPermissions(node, data);
  } catch {
    node.textContent = i18n("discourse_visible_permissions.load_error");
  }
}

function decorateShowPermissions(elem) {
  const nodes = elem.querySelectorAll("span.discourse-visible-permissions");

  nodes.forEach((node) => {
    if (node.dataset.visiblePermissionsLoaded === "true") {
      return;
    }

    node.dataset.visiblePermissionsLoaded = "true";
    loadPermissions(node);
  });
}

export default {
  name: "discourse-visible-permissions",
  initialize() {
    withPluginApi((api) => {
      const siteSettings = api.container.lookup("service:site-settings");

      if (!siteSettings.discourse_visible_permissions_enabled) {
        return;
      }

      api.decorateCookedElement(decorateShowPermissions, {
        id: "discourse-visible-permissions",
      });
    });
  },
};
