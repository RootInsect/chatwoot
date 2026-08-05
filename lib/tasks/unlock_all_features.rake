# frozen_string_literal: true

namespace :chatwoot do
  desc 'Unlock all account feature flags only (requires CHATWOOT_UNLOCK_ALL_FEATURES=true)'
  task unlock_all_features: :environment do
    result = Internal::UnlockAllFeaturesService.new.perform
    if result[:unlocked]
      puts "Unlocked #{result[:features]} feature flags on #{result[:accounts]} account(s) (plan/limits unchanged)"
    else
      puts "Skipped: #{result[:reason]}"
      exit 1
    end
  end
end
