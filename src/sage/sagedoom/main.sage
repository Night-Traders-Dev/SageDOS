# main.sage — SageDoom entry point
# Launch the terminal raycaster engine from SageDOS or standalone.
import sys
from game import Game

proc main():
    # Default terminal size
    let scr_w = 80
    let scr_h = 24

    # Check for custom resolution from env or args
    let w_env = sys.getenv("SAGEDOOM_WIDTH")
    if w_env != nil and w_env != "":
        scr_w = tonumber(w_env)
    let h_env = sys.getenv("SAGEDOOM_HEIGHT")
    if h_env != nil and h_env != "":
        scr_h = tonumber(h_env)

    let args = sys.args()
    if len(args) > 1:
        scr_w = tonumber(args[1])
    if len(args) > 2:
        scr_h = tonumber(args[2])

    if scr_w < 40:
        scr_w = 40
    if scr_h < 12:
        scr_h = 12

    let game = Game(scr_w, scr_h)
    game.run_interactive()

main()
