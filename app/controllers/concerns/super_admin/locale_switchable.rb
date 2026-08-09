module SuperAdmin::LocaleSwitchable
  extend ActiveSupport::Concern

  SUPPORTED_LOCALES = %w[en zh_CN].freeze

  included do
    around_action :use_super_admin_locale
    helper_method :super_admin_locale
  end

  private

  def use_super_admin_locale(&)
    I18n.with_locale(super_admin_locale, &)
  end

  def super_admin_locale
    @super_admin_locale ||= resolve_super_admin_locale
  end

  def resolve_super_admin_locale
    candidate = session[:super_admin_locale]
    candidate ||= current_super_admin_locale_preference
    candidate ||= ENV.fetch('DEFAULT_LOCALE', nil)
    normalize_super_admin_locale(candidate)
  end

  def current_super_admin_locale_preference
    fetch_current_super_admin&.ui_settings&.to_h&.dig('super_admin_locale')
  end

  def normalize_super_admin_locale(locale)
    locale = locale.to_s
    return locale if SUPPORTED_LOCALES.include?(locale)
    return 'zh_CN' if locale.start_with?('zh')

    'en'
  end

  def persist_super_admin_locale!(locale)
    locale = normalize_super_admin_locale(locale)
    return unless SUPPORTED_LOCALES.include?(locale)

    session[:super_admin_locale] = locale
    @super_admin_locale = locale
    persist_locale_preference!(locale)
    locale
  end

  def persist_locale_preference!(locale)
    admin = fetch_current_super_admin
    return unless admin

    settings = (admin.ui_settings || {}).to_h.merge('super_admin_locale' => locale)
    admin.update_column(:ui_settings, settings)
  rescue StandardError => e
    Rails.logger.warn("[SuperAdmin::LocaleSwitchable] persist locale preference failed: #{e.class}: #{e.message}")
    nil
  end

  # Avoid Object#respond_to? / controller helpers edge-cases during Devise sign-in.
  def fetch_current_super_admin
    return unless defined?(current_super_admin)

    current_super_admin
  rescue StandardError
    nil
  end
end
