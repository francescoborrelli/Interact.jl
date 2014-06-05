# IJulia specific code goes here.
# Assume IJulia is running


const ijulia_js = readall(joinpath(dirname(Base.source_path()), "ijulia.js"))

try
    display("text/html", """<script charset="utf-8">$(_js)</script>""")
catch
end

using Main.IJulia
using Main.IJulia.CommManager
import Main.IJulia: metadata
using InputWidgets

const comms = Dict{Int, Comm}()
const signals = Dict{String, Signal}()

function send_update(comm :: Comm, v)
    # do this better!!
    # Thoughts:
    #    Queue upto 3, buffer others
    #    Diff and send
    #    Is display_dict the right thing?
    send_comm(comm, ["value" => Main.IJulia.display_dict(v)])
end


function Main.IJulia.metadata(x :: Signal)
    if ~haskey(comms, x.id)
        # One Comm channel per signal object
        comm = Comm("signal")

        comms[x.id] = comm   # Backend -> Comm
        signals[comm.id] = x # Comm -> Backend

        # prevent resending first time?
        lift(v -> send_update(comm, v), x)
        if isa(x, Input)
            # lift(recv_update, inbound_signal(x))
        end
    else
        comm = comms[x.id]
    end
    return ["reactive"=>true, "comm_id"=>comm.id]
end

# Ideally, overriding display_dict is not necessary
Main.IJulia.display_dict(x :: Signal) =
    Main.IJulia.display_dict(x.value)


mimewritable(m :: MIME, s :: Signal) =
    mimewritable(m, s.value)


writemime(m :: MIME, s :: Signal) =
    writemime(m, s.value)
