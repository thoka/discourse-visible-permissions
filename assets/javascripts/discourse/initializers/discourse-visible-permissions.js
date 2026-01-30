import { ajax } from "discourse/lib/ajax";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";
import iconHTML from "discourse-common/lib/icon-helpers";

function renderPermissionsTable(node, data) {
  const table = document.createElement("div");
  table.classList.add("category-permissions-table");
  table.classList.add("discourse-visible-permissions-table");

  const header = document.createElement("div");
  header.classList.add("permission-row", "row-header");
  header.innerHTML = `
    <span class="group-name">${i18n("groups.index.title")}</span>
    <span class="options">
      <span class="cell">${iconHTML("far-eye")}</span>
      <span class="cell">${iconHTML("reply")}</span>
      <span class="cell">${iconHTML("plus")}</span>
    </span>
  `;
  table.appendChild(header);

  data.group_permissions.forEach((perm) => {
    const row = document.createElement("div");
    row.classList.add("permission-row", "row-body");

    const canReply = perm.permission_type <= 2; // full(1) or create_post(2)
    const canCreate = perm.permission_type === 1; // full(1)

    row.innerHTML = `
      <span class="group-name">
        <span class="group-name-label">${perm.group_name}</span>
      </span>
      <span class="options">
        <span class="cell">${iconHTML("check-square")}</span>
        <span class="cell">${canReply ? iconHTML("check-square") : iconHTML("far-square")}</span>
        <span class="cell">${canCreate ? iconHTML("check-square") : iconHTML("far-square")}</span>
      </span>
    `;
    table.appendChild(row);
  });

  node.textContent = "";
  node.appendChild(table);
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
    renderPermissionsTable(node, data);
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
