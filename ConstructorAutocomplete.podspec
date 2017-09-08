Pod::Spec.new do |spec|
  spec.name         = 'ConstructorAutocomplete'
  spec.version      = '0.0.1'
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.homepage     = 'https://www.constructor.io'
  spec.authors      = { 'Nikola Markovic' => 'nikola.markovic@toptal.com'  }
  spec.summary      = 'Constructor.io iOS autosuggest client.'
  spec.source       = { :git => 'https://github.com/Constructor-io/constructorio-client-swift.git', :tag => "v#{spec.version}" }
  spec.platform 	= :ios, '8.0'
  
  spec.source_files       	  = 'AutocompleteClient/*'
  spec.ios.resource_bundle 	  = { 'ConstructorAutocomplete' => 'AutocompleteClient/Resources/*.png' }
  spec.framework	          = 'UIKit'
end