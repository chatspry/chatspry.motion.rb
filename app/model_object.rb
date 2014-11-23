class CSModel
  attr_accessor :modelsById
  def initialize
    self.modelsById = Hash.new
    modelsById['user'] = Hash.new
    modelsById['convo'] = Hash.new
  end

  @@sharedModel = CSModel.new

  def self.sharedModel
    @@sharedModel
  end
end

module CSUniqueObject

  def self.included(klass)
    klass.extend(ClassMethods)
  end

  module ClassMethods
    def uniqueObjectWithId(uniqueId)
      cache = CSModel.sharedModel.modelsById[self.modelName]
      obj = cache[uniqueId]
      if obj == nil
        obj = self.new
        obj.uniqueId = uniqueId
        cache[uniqueId] = obj
      end
      obj
    end

    def modelName
      NSStringFromClass(self).substringFromIndex(2).lowercaseString
    end
  end
end

class CSModelObject < NSObject
  attr_accessor :uniqueId, :createdAt, :updatedAt
  include CSUniqueObject

  def updateWithJSON(json)
    self.uniqueId = NSUUID.alloc.initWithUUIDString(json[:id])
    self.createdAt = processValue(json[:created_at]) {|v| NSDate.dateWithTimeIntervalSince1970(v)}
    self.updatedAt = processValue(json[:updated_at]) {|v| NSDate.dateWithTimeIntervalSince1970(v)}
  end

  def jsonValue
    nil
  end

  def processValue(value)
    if !value.nil?
      yield value
    end
    nil
  end
end

class CSUser < CSModelObject
  attr_accessor :name, :handle

  def updateWithJSON(json)
    super
    self.name = json[:name]
    self.handle = json[:handle]
  end
end

class CSConvo < CSModelObject
  attr_accessor :name, :lang, :creator

  def updateWithJSON(json)
    super
    self.name = json[:name]
    self.lang = json[:lang]
    self.creator = CSUser.uniqueObjectWithId(NSUUID.alloc.initWithUUIDString(json[:creator][:id]))
  end
end

class CSMembership < CSModelObject
  attr_accessor :convo, :user

  def updateWithJSON(json)
    super
    self.convo = CSConvo.uniqueObjectWithId(NSUUID.alloc.initWithUUIDString(json[:convo][:id]))
    self.user = CSUser.uniqueObjectWithId(NSUUID.alloc.initWithUUIDString(json[:user][:id]))
  end
end

class CSResponse < CSModelObject

end

class CSUserConvosResponse < CSResponse
  attr_accessor :userId, :convos, :memberships
  def updateWithJSON(json)
    super
    self.userId = NSUUID.alloc.initWithUUIDString(json[:user_id])
    self.convos = json[:convos].map do |convo_json|
      uid = NSUUID.alloc.initWithUUIDString(convo_json[:id])
      convo = CSConvo.uniqueObjectWithId(uid)
      convo.updateWithJSON(convo_json)
      convo
    end
    self.memberships = json[:memberships].map do |membership_json|
      membership = CSMembership.new
      membership.updateWithJSON(membership_json)
      membership
    end
  end
end
