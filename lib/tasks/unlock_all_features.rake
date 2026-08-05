# frozen_string_literal: true

namespace :chatwoot do
  desc 'Unlock all premium/account features (requires CHATWOOT_UNLOCK_ALL_FEATURES=true)'
  task unlock_all_features: :environment do
    result = Internal::UnlockAllFeaturesService.new.perform
    if result[:unlocked]
      puts "Unlocked #{result[:features]} features on #{result[:accounts]} account(s); INSTALLATION_PRICING_PLAN=enterprise"
    else
      puts "Skipped: #{result[:reason]}"
      exit 1
    end
  end
end
