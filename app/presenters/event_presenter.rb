class EventPresenter < BasePresenter
  PRESENTER = { workshop: 'WorkshopPresenter',
                course: 'CoursePresenter',
                meeting: 'MeetingPresenter',
                event: 'EventPresenter' }.freeze

  def self.decorate_collection(collection)
    collection.map { |e| PRESENTER[e.class.to_s.downcase.to_sym].constantize.new(e) }
  end

  def chapter
    model.try(:chapter)
  end

  delegate :venue, :sponsors, to: :model

  def invitable
    model.invitable || false
  end

  def description
    model&.description
  end

  def short_description
    model.short_description rescue model.description
  end

  def organisers
    @organisers ||= model.permissions.find_by(name: 'organiser').members rescue []
  end

  def month
    I18n.l(model.date_and_time, format: :month).upcase
  end

  def time
    I18n.l(model.date_and_time, format: :time)
  end

  def path
    model
  end

  def class_string
    model.class.to_s.downcase
  end

  def questionnaire(invitation)
    invitation.for_coach? ? coach_questionnaire : student_questionnaire
  end

  def admin_path
    Rails.application.routes.url_helpers.admin_event_path(model)
  end

  def spaces?
    coach_spaces? || student_spaces?
  end

  def coach_spaces?
    venue.present? && (venue.coach_spots > attending_coaches.length)
  end

  def student_spaces?
    venue.present? && (venue.seats > attending_students.length)
  end

  def event_coach_spaces?
    model.coach_spaces?
  end

  def event_student_spaces?
    model.student_spaces?
  end

  def attendees_csv
    generate_csv_from_array(attendee_array)
  end

  private

  def generate_csv_from_array(attendees)
    CSV.generate { |csv| attendees.each { |a| csv << a } }
  end

  def attendee_array
    model.attendances.map { |i| [i.member.full_name, i.role.upcase] }
  end

  def chapter_organisers
    model.chapter.permissions.find_by(name: 'organiser').members rescue []
  end
end
