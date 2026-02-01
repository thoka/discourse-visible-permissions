import { ajax } from "discourse/lib/ajax";
import { iconHTML } from "discourse/lib/icon-library";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

function getNotificationLevelsHtml(notificationLevels) {
  const html = [];
  // Levels in order: Watching(3), Watching First(4), Tracking(2), Muted(0)
  [3, 4, 2, 0].forEach((lvl) => {
    const count = notificationLevels[lvl] || 0;
    if (count > 0) {
      let icon, levelTitle, className;
      if (lvl === 3) {
        icon = iconHTML("d-watching");
        levelTitle = i18n(
          "discourse_visible_permissions.notification_levels.watching"
        );
        className = "level-watching";
      } else if (lvl === 4) {
        icon = iconHTML("d-watching-first");
        levelTitle = i18n(
          "discourse_visible_permissions.notification_levels.watching_first_post"
        );
        className = "level-watching-first";
      } else if (lvl === 2) {
        icon = iconHTML("d-tracking");
        levelTitle = i18n(
          "discourse_visible_permissions.notification_levels.tracking"
        );
        className = "level-tracking";
      } else {
        icon = iconHTML("d-muted");
        levelTitle = i18n(
          "discourse_visible_permissions.notification_levels.muted"
        );
        className = "level-muted";
      }

      const notifiedText = i18n(
        "discourse_visible_permissions.notified_count",
        {
          count,
        }
      );

      html.push(`
          <span class="notification-level-item ${className}" title="${levelTitle}: ${notifiedText}">
            <span class="notification-icon">${icon}</span>
            <span class="notification-count">${count}</span>
          </span>
        `);
    }
  });
  return html.join("");
}

function renderClassicView(node, data) {
  const wrapper = document.createElement("div");
  wrapper.classList.add("discourse-visible-permissions-container");
  wrapper.classList.add("view-classic");

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

  const table = document.createElement("table");
  table.classList.add("discourse-visible-permissions-table");

  const thead = document.createElement("thead");
  thead.innerHTML = `
    <tr>
      <th class="group-name-header">${i18n("groups.index.title")}</th>
      <th class="actions-header"></th>
      <th class="permission-header" title="${i18n("category.permissions.see")}">${iconHTML("eye")}</th>
      <th class="permission-header" title="${i18n("category.permissions.reply")}">${iconHTML("reply")}</th>
      <th class="permission-header" title="${i18n("category.permissions.create")}">${iconHTML("plus")}</th>
      <th class="notification-header"></th>
    </tr>
  `;
  table.appendChild(thead);

  const tbody = document.createElement("tbody");
  data.group_permissions.forEach((perm) => {
    const tr = document.createElement("tr");

    const pt = perm.permission_type;
    const canSee = pt !== null && pt !== undefined;
    const canReply = canSee && pt <= 2; // full(1) or create_post(2)
    const canCreate = pt === 1; // full(1)

    const actionIcons = [];
    if (perm.can_join) {
      const joinTitle = i18n("discourse_visible_permissions.join");
      actionIcons.push(
        `<a href="${perm.group_url}" title="${joinTitle}" class="group-action-link join-action"><span class="d-icon-container">${iconHTML("user-plus")}</span></a>`
      );
    }
    if (perm.can_request) {
      const requestTitle = i18n("discourse_visible_permissions.request");
      actionIcons.push(
        `<a href="${perm.group_url}" title="${requestTitle}" class="group-action-link request-action"><span class="d-icon-container">${iconHTML("paper-plane")}</span></a>`
      );
    }

    tr.innerHTML = `
      <td class="group-name-cell">
        ${
          perm.group_url
            ? `<a href="${perm.group_url}" class="group-name-link">${perm.group_display_name}</a>`
            : `<span class="group-name-label">${perm.group_display_name}</span>`
        }
      </td>
      <td class="actions-cell">${actionIcons.join("")}</td>
      <td class="permission-cell" title="${i18n(
        "category.permissions.see"
      )}">${canSee ? iconHTML("square-check") : iconHTML("far-square")}</td>
      <td class="permission-cell" title="${i18n(
        "category.permissions.reply"
      )}">${canReply ? iconHTML("square-check") : iconHTML("far-square")}</td>
      <td class="permission-cell" title="${i18n(
        "category.permissions.create"
      )}">${canCreate ? iconHTML("square-check") : iconHTML("far-square")}</td>
      <td class="notification-cell">
        <div class="notification-levels-container">
          ${getNotificationLevelsHtml(perm.notification_levels)}
        </div>
      </td>
    `;
    tbody.appendChild(tr);
  });

  if (data.category_notification_totals) {
    const summaryTr = document.createElement("tr");
    summaryTr.classList.add("summary-row");
    summaryTr.innerHTML = `
      <td class="group-name-cell">${i18n("discourse_visible_permissions.total")}</td>
      <td class="actions-cell"></td>
      <td class="permission-cell"></td>
      <td class="permission-cell"></td>
      <td class="permission-cell"></td>
      <td class="notification-cell">
        <div class="notification-levels-container">
          ${getNotificationLevelsHtml(data.category_notification_totals)}
        </div>
      </td>
    `;
    tbody.appendChild(summaryTr);
  }

  table.appendChild(tbody);

  wrapper.appendChild(table);
  node.textContent = "";
  node.appendChild(wrapper);
}

function renderPermissionsTable(node, data, siteSettings) {
  const wrapper = document.createElement("div");
  wrapper.classList.add("discourse-visible-permissions-container");
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

  const table = document.createElement("table");
  table.classList.add("discourse-visible-permissions-table", "modern-view");

  const tbody = document.createElement("tbody");
  data.group_permissions.forEach((perm) => {
    const tr = document.createElement("tr");

    const actionIcons = [];
    if (perm.can_join) {
      const joinTitle = i18n("discourse_visible_permissions.join");
      actionIcons.push(
        `<a href="${perm.group_url}" title="${joinTitle}" class="group-action-link join-action"><span class="d-icon-container">${iconHTML("user-plus")}</span></a>`
      );
    }
    if (perm.can_request) {
      const requestTitle = i18n("discourse_visible_permissions.request");
      actionIcons.push(
        `<a href="${perm.group_url}" title="${requestTitle}" class="group-action-link request-action"><span class="d-icon-container">${iconHTML("paper-plane")}</span></a>`
      );
    }

    let permIcon, permColor, permTitle;
    if (perm.permission_type === 1) {
      permIcon = iconHTML("plus");
      permColor = siteSettings.discourse_visible_permissions_color_create;
      permTitle = i18n("category.permissions.create");
    } else if (perm.permission_type === 2) {
      permIcon = iconHTML("reply");
      permColor = siteSettings.discourse_visible_permissions_color_reply;
      permTitle = i18n("category.permissions.reply");
    } else if (perm.permission_type === 3) {
      permIcon = iconHTML("eye");
      permColor = siteSettings.discourse_visible_permissions_color_see;
      permTitle = i18n("category.permissions.see");
    } else {
      // No permission explicitly set, but shown because of notification defaults
      permIcon = "";
      permColor = "transparent";
      permTitle = "";
    }

    tr.innerHTML = `
      <td class="group-name-cell">
        ${
          perm.group_url
            ? `<a href="${perm.group_url}" class="group-name-link">${perm.group_display_name}</a>`
            : `<span class="group-name-label">${perm.group_display_name}</span>`
        }
      </td>
      <td class="actions-cell">${actionIcons.join("")}</td>
      <td class="permission-badge-cell">
        ${
          permIcon
            ? `<span class="permission-badge" style="background-color: ${permColor}" title="${permTitle}">
          ${permIcon}
        </span>`
            : ""
        }
      </td>
      <td class="notification-cell">
        <div class="notification-levels-container">
          ${getNotificationLevelsHtml(perm.notification_levels)}
        </div>
      </td>
    `;
    tbody.appendChild(tr);
  });

  if (data.category_notification_totals) {
    const summaryTr = document.createElement("tr");
    summaryTr.classList.add("summary-row");
    summaryTr.innerHTML = `
      <td class="group-name-cell">${i18n("discourse_visible_permissions.total")}</td>
      <td class="actions-cell"></td>
      <td class="permission-badge-cell"></td>
      <td class="notification-cell">
        <div class="notification-levels-container">
          ${getNotificationLevelsHtml(data.category_notification_totals)}
        </div>
      </td>
    `;
    tbody.appendChild(summaryTr);
  }

  table.appendChild(tbody);

  wrapper.appendChild(table);
  node.textContent = "";
  node.appendChild(wrapper);
}

function renderShortView(node, data) {
  const wrapper = document.createElement("div");
  wrapper.classList.add("discourse-visible-permissions-container");
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
          const joinTitle = i18n("discourse_visible_permissions.join");
          actionIcons.push(
            `<a href="${p.group_url}" title="${joinTitle}" class="group-action-link join-action"><span class="d-icon-container">${iconHTML("user-plus")}</span></a>`
          );
        }
        if (p.can_request) {
          const requestTitle = i18n("discourse_visible_permissions.request");
          actionIcons.push(
            `<a href="${p.group_url}" title="${requestTitle}" class="group-action-link request-action"><span class="d-icon-container">${iconHTML("paper-plane")}</span></a>`
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
    ${renderSection("eye", seeGroups)}
  `;

  wrapper.appendChild(container);
  node.textContent = "";
  node.appendChild(wrapper);
}

async function loadPermissions(node, api) {
  const categoryId = node.dataset.category;
  const view =
    node.dataset.view ||
    api.container.lookup("service:site-settings")
      .discourse_visible_permissions_default_view;

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
    const siteSettings = api.container.lookup("service:site-settings");

    if (view === "short") {
      renderShortView(node, data);
    } else if (view === "classic") {
      renderClassicView(node, data);
    } else {
      renderPermissionsTable(node, data, siteSettings);
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
