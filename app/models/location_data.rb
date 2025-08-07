class LocationData
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :latitude, :float
  attribute :longitude, :float
  attribute :name, :string

  validates_presence_of :latitude
  validates_presence_of :longitude
end
