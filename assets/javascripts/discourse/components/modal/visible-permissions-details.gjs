import Component from "@glimmer/component";
import DModal from "discourse/components/d-modal";
import { i18n } from "discourse-i18n";
import VisiblePermissionsTable from "../visible-permissions/table";

export default class VisiblePermissionsDetails extends Component {
  get data() {
    return this.args.model.data;
  }

  get categoryId() {
    return this.args.model.categoryId;
  }

  get tableTitle() {
    return i18n("discourse_visible_permissions.table_title", {
      category_name: this.data.category_name,
    });
  }

  <template>
    <DModal
      @title={{i18n "discourse_visible_permissions.modal_title"}}
      @closeModal={{@closeModal}}
      class="visible-permissions-details-modal"
    >
      <:body>
        <VisiblePermissionsTable
          @data={{@model.permissions}}
          @categoryId={{@model.categoryId}}
        />
      </:body>
    </DModal>
  </template>
}
