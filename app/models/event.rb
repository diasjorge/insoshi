class Event < ActiveRecord::Base
  include ActivityLogger

  MAX_DESCRIPTION_LENGTH = MAX_STRING_LENGTH
  MAX_LOCATION_LENGTH = MAX_STRING_LENGTH
  MAX_TITLE_LENGTH = 40
  PRIVACY = { :public => 1, :contacts => 2 }
  FEED_SIZE = 10

  belongs_to :person
  belongs_to :category
  has_many :event_attendees
  has_many :attendees, :through => :event_attendees, :source => :person
  has_many :comments, :as => :commentable, :order => 'created_at DESC'
  has_many :activities, :foreign_key => "item_id", :dependent => :destroy

  validates_presence_of :title, :start_time, :person, :privacy, :category
  validates_length_of :title, :maximum => MAX_TITLE_LENGTH
  validates_length_of :description, :maximum => MAX_DESCRIPTION_LENGTH, :allow_blank => true
  validates_length_of :location, :maximum => MAX_LOCATION_LENGTH, :allow_blank => true

  named_scope :person_events, 
              lambda { |person| { :conditions => ["person_id = ? OR (privacy = ? OR (privacy = ? AND (person_id IN (?))))", 
                                                  person.id,
                                                  PRIVACY[:public], 
                                                  PRIVACY[:contacts], 
                                                  person.contact_ids] } }

  named_scope :period_events,
              lambda { |date_from, date_until| { :conditions => ['start_time >= ? and start_time <= ?',
                                                 date_from, date_until] } }

  after_create :log_activity
  
  def self.monthly_events(date)
    self.period_events(date.beginning_of_month, date.to_time.end_of_month)
  end
  
  def self.daily_events(date)
    self.period_events(date.beginning_of_day, date.to_time.end_of_day)
  end

  def feed
    sql = "(item_id = ? AND item_type = 'Event') OR (item_type = 'EventAttendee' and item_id in (?)) OR (item_type = 'Comment' and item_id in (?))"
    activities = Activity.find(:all, 
                               :conditions => [sql,Event.first,self.event_attendee_ids,self.comment_ids],
                               :order => 'created_at desc',
                               :limit => FEED_SIZE)
  end

  def validate
    if end_time
      unless start_time <= end_time
        errors.add(:start_time, "can't be later than End Time")
      end
    end
  end
  
  def attend(person)
    self.event_attendees.create!(:person => person)
  rescue ActiveRecord::RecordInvalid
    nil
  end

  def unattend(person)
    if event_attendee = self.event_attendees.find_by_person_id(person)
        event_attendee.destroy
    else
      nil
    end
  end

  def attending?(person)
    self.attendee_ids.include?(person[:id])
  end

  def only_contacts?
    self.privacy == PRIVACY[:contacts]
  end

  private

    def log_activity
      add_activities(:item => self, :person => self.person)
    end

end
