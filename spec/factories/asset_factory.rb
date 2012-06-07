# encoding: utf-8
FactoryGirl.define do
  factory :asset_avatar, :class => Avatar do |a|
    #include ActionDispatch::TestProcess
    a.data File.open('spec/factories/files/rails.png')
    a.association :assetable, :factory => :default_user
  end

  factory :asset_avatar_big, :class => Avatar do |a|
    a.data File.open('spec/factories/files/silicon_valley.jpg')
    a.association :assetable, :factory => :default_user
  end
end