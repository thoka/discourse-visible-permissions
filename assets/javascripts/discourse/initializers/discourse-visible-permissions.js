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
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error("Error loading category permissions:", e);
    node.textContent = i18n("discourse_visible_permissions.load_error");
  }
}

function decorateShowPermissions(elem, helper) {
  const nodes = elem.querySelectorAll("span.discourse-visible-permissions");

  let contextCategoryId;
  if (helper) {
    const model = helper.getModel();
    if (model) {
      contextCategoryId = model.topic?.category_id || model.category_id;
    }
  }

  nodes.forEach((node) => {
    if (node.dataset.visiblePermissionsLoaded === "true") {
      return;
    }

    if (!node.dataset.category && contextCategoryId) {
      node.dataset.category = contextCategoryId;
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

      // eslint-disable-next-line no-console
      console.log("Visible permissions initializer running. Enabled:", siteSettings.discourse_visible_permissions_enabled);

      if (!siteSettings.discourse_visible_permissions_enabled) {
        return;
      }

      api.decorateCookedElement(decorateShowPermissions, {
        id: "discourse-visible-permissions",
      });
    });
  },
};
