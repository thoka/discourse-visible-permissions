import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import VisiblePermissionsTable from "discourse/plugins/discourse-visible-permissions/discourse/components/visible-permissions/table";

module("Integration | Component | visible-permissions/table", function (hooks) {
  setupRenderingTest(hooks);

  test("it renders notification counts and summary row correctly", async function (assert) {
    this.set("data", {
      category_name: "Test Category",
      group_permissions: [
        {
          group_id: 10,
          group_name: "trust_level_0",
          group_display_name: "Trust Level 0",
          user_count: 100,
          permission_type: 3,
          notification_level_counts: { 3: 42, 4: 0, 2: 5, 0: 1 },
        },
      ],
      category_notification_totals: {
        3: 50,
        4: 2,
        2: 10,
        0: 5
      }
    });

    await render(<template><VisiblePermissionsTable @data={{this.data}} /></template>);

    // Basic data check
    assert.dom(".notification-cell.level-3").hasText("42", "renders watching count for group");
    
    // Summary row check
    assert.dom(".summary-row").exists("summary row exists");
    assert.dom(".summary-row .level-3").hasText("50", "renders total watching count");
    assert.dom(".summary-row .level-4").hasText("2", "renders total watching first post count");
  });
});
