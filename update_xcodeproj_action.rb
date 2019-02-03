# frozen_string_literal: true

module Fastlane
  module Actions
    class UpdateXcodeprojAction < Action
      def self.run(params)
        require 'xcodeproj'

        project_path = params[:xcodeproj_path]
        plist_path = params[:plist_path]
        plist_options = params[:plist]
        build_settings = params[:build_settings]
        capabilities = params[:capabilities]
        frameworks = params[:frameworks]
        other_ldflags = params[:other_ldflags]
        entitlements = params[:entitlements]
        entitlements_path = params[:entitlements_path]
        @@verbose = params[:verbose]

        project = Xcodeproj::Project.open(project_path)

        update_entitlements(project, entitlements_path, entitlements) unless entitlements.nil?
        update_capabilities(project, capabilities) unless capabilities.nil?
        update_build_settings(project, build_settings) unless build_settings.nil?
        update_plist(plist_path, plist_options) unless plist_options.nil? || plist_path.nil?
        update_frameworks(project, frameworks) unless frameworks.nil?
        update_other_ldflags(project, other_ldflags) unless other_ldflags.nil?

        project.save

        log_success("Updated #{project_path} 💾.")
      end

      def self.update_entitlements(project, entitlements_path, entitlements_options)
        log_important('Updating Entitlements 🚀')
        log_message(" - Creating Entitlements file in #{entitlements_path}") unless File.exist?(entitlements_path)
        log_message(" - Updating Entitlements file in #{entitlements_path}") if File.exist?(entitlements_path)
        reference_file = !File.exist?(entitlements_path)
        Xcodeproj::Plist.write_to_path(entitlements_options, entitlements_path)
        log_important('Referencing Entitlements file into the project 🚀') if reference_file
        project.new_file(entitlements_path) if reference_file

        log_success('Entitlements Successfully Updated ✅.')
      end

      def self.update_build_settings(project, build_settings)
        log_important('Updating Build Settings 🚀')
        current_target = project.native_targets.first
        build_settings.each do |key, value|
          current_target.build_configurations.each do |config|
            build_settings = config.build_settings
            if value.is_a?(TrueClass) || value.is_a?(FalseClass)
              log_message(" - Updating #{key} to #{value.is_a?(TrueClass) ? 'YES' : 'NO'} in #{config}")
              build_settings[key.to_s] = value.is_a?(TrueClass) ? 'YES' : 'NO'
            else
              log_message(" - Updating #{key} to #{value} in #{config}")
              build_settings[key.to_s] = value
            end
          end
        end
        log_success('Build Settings Successfully Updated ✅.')
      end

      def self.update_other_ldflags(project, other_ldflags)
        log_important('Updating OtherLdFlags 🚀')
        current_target = project.native_targets.first
        other_ldflags.each do |flag|
          current_target.build_configurations.each do |config|
            build_settings = config.build_settings
            other_flags = build_settings['OTHER_LDFLAGS']
            log_message(" - Updating OtherLdFlags #{flag} in #{config}")
            other_flags << flag unless other_flags.nil? || other_flags.include?(flag) || !other_flags.is_a?(Array)
            config.build_settings['OTHER_LDFLAGS'] = other_flags
          end
        end
        log_success('OtherLdFlags Successfully Updated ✅.')
      end

      def self.update_frameworks(project, frameworks)
        log_important('Updating Frameworks 🚀')
        current_target = project.native_targets.first
        frameworks.each do |framework|
          next unless project.frameworks_group.children.any? { |child| child.name == "#{framework}.framework" }
          log_message(" - Updating #{framework}")
          file = project.frameworks_group.new_reference("System/Library/Frameworks/#{framework}.framework", :sdk_root)
          current_target.frameworks_build_phases.add_file_reference(file, true)
        end
        log_success('Frameworks Successfully Updated ✅.')
      end

      def self.update_plist(plist_path, plist_options)
        log_important('Updating Plist 🚀')
        plist = Xcodeproj::Plist.read_from_path(plist_path) unless plist_path.nil?
        plist_options.each do |key, value|
          log_message(" - Creating #{key} cause it does not exists in Plist") unless plist.include?(key.to_s)
          log_message(" - Updating #{key}") if plist.include?(key.to_s)
          plist[key.to_s] = value
        end
        Xcodeproj::Plist.write_to_path(plist, plist_path)
        log_success('Plist Successfully Updated ✅.')
      end

      def self.update_capabilities(project, capabilities)
        log_important('Updating Capabilities 🚀')
        current_target = project.native_targets.first
        target_id = current_target.uuid
        system_capabilities = {}
        attributes = {}
        capabilities.each do |key, value|
          log_message(" - Updating #{capability_bundle(key)} to #{value ? 1 : 0}")
          system_capabilities[capability_bundle(key).to_s] = { enabled: value ? 1 : 0 }
        end
        attributes[target_id] = { SystemCapabilities: system_capabilities }
        project.root_object.attributes['TargetAttributes'] = attributes
        log_success('Capabilities Successfully Updated ✅.')
      end

      def self.log_success(message)
        UI.success message if @@verbose
      end

      def self.log_error_and_exit(message)
        UI.user_error! message
      end

      def self.log_message(message)
        UI.message message if @@verbose
      end

      def self.log_important(message)
        UI.important message if @@verbose
      end

      def self.description
        'Update Xcode projects'
      end

      def self.authors
        ['Martin Gonzalez']
      end

      def self.available_options
        [FastlaneCore::ConfigItem.new(key: :xcodeproj_path,
                                      env_name: 'XCODEPROJ_PATH',
                                      description: 'Path to your Xcode project',
                                      type: String,
                                      verify_block: proc do |value|
                                        UI.user_error!('Please pass the path to the project, not the workspace') unless value.end_with?('.xcodeproj')
                                        UI.user_error!('Could not find Xcode project') unless File.exist?(value)
                                      end),
         FastlaneCore::ConfigItem.new(key: :plist_path,
                                      env_name: 'PLIST_PATH',
                                      description: 'Path to your plist',
                                      optional: true,
                                      type: String,
                                      verify_block: proc do |value|
                                        UI.user_error!('Please pass the path to the plist') unless value.end_with?('.plist')
                                        UI.user_error!('Could not find plist path') unless File.exist?(value)
                                      end),
         FastlaneCore::ConfigItem.new(key: :entitlements_path,
                                      env_name: 'ENTITLEMENTS_PATH',
                                      description: 'Path to your .entitlements file, or where should be created',
                                      optional: true,
                                      type: String),
         FastlaneCore::ConfigItem.new(key: :plist,
                                      description: 'plist configuration',
                                      optional: true,
                                      type: Hash),
         FastlaneCore::ConfigItem.new(key: :entitlements,
                                      description: 'entitlements configuration',
                                      optional: true,
                                      type: Hash),
         FastlaneCore::ConfigItem.new(key: :capabilities,
                                      description: 'capabilities configuration',
                                      optional: true,
                                      type: Hash),
         FastlaneCore::ConfigItem.new(key: :build_settings,
                                      description: 'build_settings configuration',
                                      optional: true,
                                      type: Hash),
         FastlaneCore::ConfigItem.new(key: :verbose,
                                      description: 'logs every step of the action',
                                      optional: true,
                                      type: Boolean),
         FastlaneCore::ConfigItem.new(key: :frameworks,
                                      description: 'frameworks configuration',
                                      optional: true,
                                      type: Array),
         FastlaneCore::ConfigItem.new(key: :other_ldflags,
                                      description: 'other_ldflags configuration',
                                      optional: true,
                                      type: Array)]
      end

      def self.is_supported?(platform)
        %i[ios mac].include?(platform)
      end

      def self.capability_bundle(capability)
        case capability
        when :push_notifications
          'com.apple.Push'
        when :in_app_purchases
          'com.apple.InAppPurchase'
        when :game_center
          'com.apple.GameCenter.iOS'
        when :apple_pay
          'com.apple.ApplePay'
        when :app_groups
          'com.apple.ApplicationGroups.iOS'
        when :access_wifi
          'com.apple.AccessWiFi'
        when :auto_fill_credentials
          'com.apple.AutoFillCredentialProvider'
        when :background_modes
          'com.apple.BackgroundModes'
        when :health_kit
          'com.apple.HealthKit'
        else
          log_error_and_exit("#{capability} is not supported or it's wrong. 💥")
        end
      end
    end
  end
end
