class SeeingIsBelieving
  # All our errors will inherit from this so that a user can catch any error generated by this lib
  SeeingIsBelievingError = Class.new StandardError

  class TempFileAlreadyExists < SeeingIsBelievingError
    def initialize(from_filename, backup_filename)
      super "Trying to back up #{from_filename.inspect} (FILE) to"\
            " #{backup_filename.inspect} (TEMPFILE) but TEMPFILE already exists."\
            " You should check the contents of these files. If FILE is correct,"\
            " then delete TEMPFILE. Otherwise rename TEMPFILE to FILE."
    end
  end

  # EventStream
  NoMoreEvents       = Class.new SeeingIsBelievingError
  UnknownEvent       = Class.new SeeingIsBelievingError
end
