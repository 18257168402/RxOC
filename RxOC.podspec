
Pod::Spec.new do |s|
    s.name         = "RxOC"
    s.version      = "1.0.0"
    s.summary      = "An iOS Rx imp."
    s.description  = <<-DESC
        it is a rx util
    DESC
    s.homepage     = 'xxxx'
    s.license      = 'MIT'
    s.author       = { 'lishusheng' => 'shusheng.li@outlook.com' }
    s.platform = :ios, '7.0'
    s.source       = { :git => "https://github.com/18257168402/RxOC.git", :tag => s.version.to_s }
    s.ios.deployment_target = '7.0'
    s.requires_arc = true
    s.frameworks   = "Foundation","UIKit"
    s.source_files = 'source/**/*.{h,m}'
    s.exclude_files = ''
    s.requires_arc = true
end
