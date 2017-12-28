def hyperspace_pod
    pod 'Hyperspace', :path => '.'
end

target 'Hyperspace-iOS' do
  platform :ios, '8.0'
  use_frameworks!

  hyperspace_pod

  target 'Hyperspace-iOSTests' do
    inherit! :search_paths
    
  end

end

target 'Hyperspace-tvOS' do
  platform :tvos, '9.0'
  use_frameworks!
  
  hyperspace_pod

  target 'Hyperspace-tvOSTests' do
    inherit! :search_paths
    
  end

end

target 'Hyperspace-watchOS' do
  platform :watchos, '2.0'
  use_frameworks!
  
  hyperspace_pod
  
end
