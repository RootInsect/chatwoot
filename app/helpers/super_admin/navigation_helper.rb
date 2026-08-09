module SuperAdmin::NavigationHelper
  def settings_open?
    params[:controller].in? %w[super_admin/settings super_admin/app_configs]
  end

  def settings_pages
    features = SuperAdmin::FeaturesHelper.available_features.select do |_feature, attrs|
      attrs['config_key'].present? && attrs['enabled']
    end

    features = features.transform_values do |attrs|
      attrs.merge('name' => translate_settings_feature_name(attrs['config_key'], attrs['name']))
    end

    # Add general at the beginning
    general_feature = [['general', {
      'config_key' => 'general',
      'name' => I18n.t('super_admin.settings.general')
    }]]

    general_feature + features.to_a
  end

  private

  def translate_settings_feature_name(config_key, default_name)
    I18n.t("super_admin.settings.features.#{config_key}", default: [
      I18n.t("super_admin.features.#{config_key}.name", default: default_name)
    ])
  end
end
