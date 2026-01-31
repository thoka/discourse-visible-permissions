import { ajax } from "discourse/lib/ajax";
import { iconHTML } from "discourse/lib/icon-library";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

function renderPermissionsTable(node, data) {
  const wrapper = document.createElement("div");
  wrapper.classList.add("discourse-visible-permissions-wrapper");
  wrapper.classList.add("view-table");

  const title = document.createElement("h3");
  title.classList.add("discourse-visible-permissions-title");

  if (data.category_url) {
    title.innerHTML = i18n("discourse_visible_permissions.table_title", {
      category_name: `<a href="${data.category_url}" class="category-name-link">${data.category_name}</a>`,
    });
  } else {
    title.textContent = i18n("discourse_visible_permissions.table_title", {
      category_name: data.category_name,
    });
  }
  wrapper.appendChild(title);

  const table = document.createElement("div");
  table.classList.add("category-permissions-table");
  table.classList.add("discourse-visible-permissions-table");

  const header = document.createElement("div");
  header.classList.add("permission-row", "row-header");
  header.innerHTML = `
    <span class="group-name">${i18n("groups.index.title")}</span>
    <span class="options">
      <span class="cell" title="${i18n("category.permissions.see")}">${iconHTML("far-eye")}</span>
      <span class="cell" title="${i18n("category.permissions.reply")}">${iconHTML("reply")}</span>
      <span class="cell" title="${i18n("category.permissions.create")}">${iconHTML("plus")}</span>
      <span class="cell actions-cell"></span>
    </span>
  `;
  table.appendChild(header);

  data.group_permissions.forEach((perm) => {
    const row = document.createElement("div");
    row.classList.add("permission-row", "row-body");

    const canReply = perm.permission_type <= 2; // full(1) or create_post(2)
    const canCreate = perm.permission_type === 1; // full(1)

    const actionIcons = [];
    if (perm.can_join) {
      actionIcons.push(
        `<a href="${perm.group_url}" title="${i18n("discourse_visible_permissions.join")}" class="group-action-link join-action">${iconHTML("user-plus")}</a>`
      );
    }
    if (perm.can_request) {
      actionIcons.push(
        `<a href="${perm.group_url}" title="${i18n("discourse_visible_permissions.request")}" class="group-action-link request-action">${iconHTML("paper-plane")}</a>`
      );
    }

    row.innerHTML = `
      <span class="group-name">
        ${
          perm.group_url
            ? `<a href="${perm.group_url}" class="group-name-link">${perm.group_display_name}</a>`
            : `<span class="group-name-label">${perm.group_display_name}</span>`
        }
      </span>
      <span class="options">
        <span class="cell" title="${i18n("category.permissions.see")}">${iconHTML("square-check")}</span>
        <span class="cell" title="${i18n("category.permissions.reply")}">${canReply ? iconHTML("square-check") : iconHTML("far-square")}</span>
        <span class="cell" title="${i18n("category.permissions.create")}">${canCreate ? iconHTML("square-check") : iconHTML("far-square")}</span>
        <span class="cell actions-cell">${actionIcons.join("")}</span>
      </span>
    `;
    table.appendChild(row);
  });

  wrapper.appendChild(table);
  node.textContent = "";
  node.appendChild(wrapper);
}

function renderShortView(node, data) {
  const wrapper = document.createElement("div");
  wrapper.classList.add("discourse-visible-permissions-wrapper");
  wrapper.classList.add("view-short");

  const title = document.createElement("h3");
  title.classList.add("discourse-visible-permissions-title");

  if (data.category_url) {
    title.innerHTML = i18n("discourse_visible_permissions.table_title", {
      category_name: `<a href="${data.category_url}" class="category-name-link">${data.category_name}</a>`,
    });
  } else {
    title.textContent = i18n("discourse_visible_permissions.table_title", {
      category_name: data.category_name,
    });
  }
  wrapper.appendChild(title);

  const container = document.createElement("div");
  container.classList.add("discourse-visible-permissions-short-container");

  const createGroups = data.group_permissions.filter(
    (p) => p.permission_type === 1
  );
  const replyGroups = data.group_permissions.filter(
    (p) => p.permission_type === 2
  );
  const seeGroups = data.group_permissions.filter(
    (p) => p.permission_type === 3
  );

  const renderSection = (icon, groups) => {
    if (groups.length === 0) {
      return "";
    }
    const groupList = groups
      .map((p) => {
        const actionIcons = [];
        if (p.can_join) {
          actionIcons.push(
            `<a href="${
              p.group_url
            }" title="${i18n("discourse_visible_permissions.join")}" class="group-action-link join-action">${iconHTML("user-plus")}</a>`
          );
        }
        if (p.can_request) {
          actionIcons.push(
            `<a href="${
              p.group_url
            }" title="${i18n("discourse_visible_permissions.request")}" class="group-action-link request-action">${iconHTML("paper-plane")}</a>`
          );
        }

        const nameContent = p.group_url
          ? `<a href="${p.group_url}" class="group-name-link">${p.group_display_name}</a>`
          : `<span class="group-name-label">${p.group_display_name}</span>`;

        return `<span class="group-item">${nameContent}${actionIcons.join(
          ""
        )}</span>`;
      })
      .join(", ");

    return `
      <div class="permission-section">
        <span class="section-icon">${iconHTML(icon)}</span>
        <span class="section-groups">${groupList}</span>
      </div>
    `;
  };

  container.innerHTML = `
    ${renderSection("plus", createGroups)}
    ${renderSection("reply", replyGroups)}
    ${renderSection("far-eye", seeGroups)}
  `;

  wrapper.appendChild(container);
  node.textContent = "";
  node.appendChild(wrapper);
}

async function loadPermissions(node, api) {
  const categoryId = node.dataset.category;
  const view =
    node.dataset.view || api.container.lookup("service:site-settings").discourse_visible_permissions_default_view;

  if (!api.getCurrentUser()) {
    node.style.display = "none";
    return;
  }

  if (!categoryId) {
    node.textContent = i18n("discourse_visible_permissions.missing_category");
    return;
  }

  node.textContent = i18n("discourse_visible_permissions.loading");

  try {
    const data = await ajax(`/c/${categoryId}/permissions.json`);
    if (view === "short") {
      renderShortView(node, data);
    } else {
      renderPermissionsTable(node, data);
    }
  } catch (e) {
    if (e.status === 403 || e.status === 404) {
      node.style.display = "none";
    } else {
      // eslint-disable-next-line no-console
      console.error("Error loading category permissions:", e);
      node.textContent = i18n("discourse_visible_permissions.load_error");
    }
  }
}

function decorateShowPermissions(elem, helper, api) {
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
    loadPermissions(node, api);
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

      api.decorateCookedElement(
        (elem, helper) => decorateShowPermissions(elem, helper, api),
        {
          id: "discourse-visible-permissions",
        }
      );
    });
  },
};
