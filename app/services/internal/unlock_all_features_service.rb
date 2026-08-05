# frozen_string_literal: true

class Internal::UnlockAllFeaturesService
  def perform
    return { unlocked: false, reason: 'CHATWOOT_UNLOCK_ALL_FEATURES is not enabled' } unless ChatwootApp.unlock_all_features?

    sync_account_feature_defaults!
    unlocked_accounts = unlock_accounts!

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
      account.enable_features!(*feature_names)
      count += 1
    end
    count
  end
end
