# TODO: delete

class Trailblazer::Activity::Schema
  class Dependencies
    def initialize
      @groups  = {
        start: Sequence.new,
        main:  Sequence.new, # normal steps
        end:   Sequence.new, # ends
      }

      @order = [ :start, :main, :end ]
      @id_to_group = { }
    end

    def add(id, seq_options, group: :main, **sequence_options)
      group = @groups[group] or raise "unknown group, implement me"

      # "upsert"
      if existing = group.send( :find_index, id) # FIXME
        arr = group[existing].instructions.dup



        arr[0] += seq_options[0] # merge the magnetic_to, only.

        group.insert!(id, arr, replace: id)

      else
        group.insert!(id, seq_options, **sequence_options) # handles
      end
    end

    # Produces something like
    #
    # [
    #   #  magnetic to
    #   #  color | signal|outputs
    #   [ [:success], A,  [R, L] ],
    #   [ [:failure], E, [L, e_to_success] ],
    #   [ [:success], B, [R, L] ],
    #   [ [:success], C, [R] ],

    #   [ [:success, :e_to_success], ES, [] ], # magnetic_to needs to have the special line, too.
    #   [ [:failure], EF, [] ],
    # ]
    def to_a
      @order.collect{ |name| @groups[name].to_a }.flatten(1)
    end
  end
end
