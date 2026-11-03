platform :ios, '15.0'

target 'TerraformGenesis' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'IQKeyboardManager'
  pod 'SDWebImage'
  pod 'YYModel'
  pod 'Masonry'
  pod 'Adjust'

end

require 'fileutils'

def ensure_framework_privacy_manifest(installer, pod_name)
  src = File.join(__dir__, 'PrivacyManifests', "#{pod_name}.xcprivacy")
  return unless File.exist?(src)

  target = installer.pods_project.targets.find { |t| t.name == pod_name }
  return unless target

  pod_root = File.join(installer.sandbox.root.to_s, pod_name)
  return if Dir.glob(File.join(pod_root, '**/PrivacyInfo.xcprivacy')).any?

  FileUtils.mkdir_p(pod_root)
  FileUtils.cp(src, File.join(pod_root, 'PrivacyInfo.xcprivacy'))

  phase = target.resources_build_phase
  return if phase.files_references.any? { |ref| ref.path.to_s.end_with?('PrivacyInfo.xcprivacy') }

  group = installer.pods_project.main_group.new_group(pod_name, pod_name)
  file_ref = group.new_file('PrivacyInfo.xcprivacy')
  phase.add_file_reference(file_ref, true)
end

post_install do |installer|
  %w[Masonry YYModel].each do |pod_name|
    ensure_framework_privacy_manifest(installer, pod_name)
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 15.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
    end
  end
end
