# frozen_string_literal: true

class Internal::UnlockAllFeaturesService
  def perform
    return { unlocked: false, reason: 'CHATWOOT_UNLOCK_ALL_FEATURES is not enabled' } unless ChatwootApp.unlock_all_features?

    set_installation_plan!
    sync_account_feature_defaults!
    unlocked_accounts = unlock_accounts!

    GlobalConfig.clear_cache

    {
      unlocked: true,
      accounts: unlocked_accounts,
      features: feature_names.size
    }
  end

  private

  def feature_names
    @feature_names ||= Featurable::FEATURE_LIST.pluck('name')
  end

  def set_installation_plan!
    update_config('INSTALLATION_PRICING_PLAN', 'enterprise')
    update_config('INSTALLATION_PRICING_PLAN_QUANTITY', ChatwootApp.max_limit)
    update_config('DEPLOYMENT_ENV', 'self-hosted')
  end

  def sync_account_feature_defaults!
    config = InstallationConfig.find_or_initialize_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    defaults = Featurable::FEATURE_LIST.map do |feature|
      feature.stringify_keys.merge('enabled' => true)
    end
    config.value = defaults
    config.save!
  end

  def unlock_accounts!
    count = 0
    Account.find_each do |account|
      account.enable_features(*feature_names)
      existing_limits = account.limits.is_a?(Hash) ? account.limits.stringify_keys : {}
      account.limits = existing_limits.merge(generous_limits)
      account.custom_attributes = (account.custom_attributes || {}).merge('plan_name' => 'Enterprise')
      account.save!
      count += 1
    end
    count
  end

  def generous_limits
    {
      'agents' => ChatwootApp.max_limit,
      'inboxes' => ChatwootApp.max_limit,
      'captain_responses' => ChatwootApp.max_limit,
      'captain_documents' => ChatwootApp.max_limit
    }
  end

  def update_config(name, value)
    config = InstallationConfig.find_or_initialize_by(name: name)
    config.value = value
    config.save!
  end
end
