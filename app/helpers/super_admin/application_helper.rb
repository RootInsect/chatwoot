module SuperAdmin::ApplicationHelper
  def application_title
    GlobalConfigService.load('INSTALLATION_NAME', 'AI客服')
  end

  def installation_name
    GlobalConfigService.load('INSTALLATION_NAME', 'AI客服')
  end

  def app_config_section_name(config_key)
    I18n.t(
      "super_admin.settings.features.#{config_key}",
      default: [
        I18n.t("super_admin.features.#{config_key}.name", default: config_key.to_s.titleize)
      ]
    )
  end

  def installation_config_title(key, config_meta = {})
    I18n.t(
      "super_admin.installation_configs.#{key}.title",
      default: [config_meta['display_title'].presence, key.to_s.humanize].compact
    )
  end

  def installation_config_description(key, config_meta = {})
    translated = I18n.t("super_admin.installation_configs.#{key}.description", default: '')
    return translated if translated.present?

    config_meta['description']
  end

  def administrate_attribute_label(resource_name, attr_name, resource_class: nil)
    I18n.t(
      "helpers.label.#{resource_name}.#{attr_name}",
      default: [
        (resource_class.human_attribute_name(attr_name) if resource_class.respond_to?(:human_attribute_name)),
        attr_name.to_s.humanize
      ].compact
    )
  end

  def administrate_filter_label(resource_name, filter_name)
    resource_key = "super_admin.filters.#{resource_name}.#{filter_name}"
    return I18n.t(resource_key) if I18n.exists?(resource_key)

    common_key = "super_admin.filters.common.#{filter_name}"
    return I18n.t(common_key) if I18n.exists?(common_key)

    filter_name.to_s.humanize
  end
end
