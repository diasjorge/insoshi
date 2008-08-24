require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Event do
  before(:each) do
    @valid_attributes = {
      :title => "value for title",
      :description => "value for description",
      :person => people(:aaron),
      :start_time => Time.now,
      :end_time => Time.now,
      :reminder => false,
      :privacy => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Event.create!(@valid_attributes)
  end

  describe "privacy settings" do
    before(:each) do
      @person = people(:aaron)
      @contact = people(:quentin)
    end
    it "should find all public events" do
      Event.person_events(@person).should include(events(:public))
    end

    it "should find contact's events" do
      @person.stub!(:contact_ids).and_return([@contact.id])
      Event.person_events(@person).should include(events(:private))
    end

    it "should find own events" do
      Event.person_events(@contact).should include(events(:private))
    end                   
    
    it 'should not find other private events who are not my friends' do
      Event.person_events(@person).should_not include(events(:private))
    end
                                       
  end

  describe "attendees association" do
    before(:each) do
      @event = events(:public)
      @person = people(:aaron)
    end
    
    it "should allow people to attend" do
      @event.attend(@person)                                   
      @event.attendees.should include(@person)
      @event.reload
      @event.event_attendees_count.should be(1)
    end

    it 'should not allow people to attend twice' do
      @event.attend(@person).should_not be_nil
      @event.attend(@person).should be_nil
    end
                                        
  end

end
