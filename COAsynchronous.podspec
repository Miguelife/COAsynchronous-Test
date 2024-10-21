Pod::Spec.new do |spec|

  spec.name         = "COAsynchronous"
  spec.version      = "0.1.0"
  spec.summary      = "COAsynchronous package."

  spec.description  = "COAsynchronous package."

  spec.homepage     = "http://Miguelife/COAsynchronous-Test"

  spec.license      = "MIT License"

  spec.author       = { "Miguel Ángel Soto" => "miguelifesoto@gmail.com" }

  spec.source       = { :git => "https://github.com/Miguelife/COAsynchronous-Test.git", :tag => "1.0.3" }

  spec.ios.deployment_target = '13.0'

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'COAsynchronous' => ['Pod/Assets/*.png']
  }
end
