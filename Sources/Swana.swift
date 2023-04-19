import ANSITerminal
import ArgumentParser
import Foundation

// MARK: - Swana

@main
struct Swana: AsyncParsableCommand {
  @Argument(help: "Project path") var projectPath: String

  mutating func run() async {
    print("                                                       ".blue.bold)
    print(" @@@@@@   @@@  @@@  @@@   @@@@@@   @@@  @@@   @@@@@@   ".blue.bold)
    print("@@@@@@@   @@@  @@@  @@@  @@@@@@@@  @@@@ @@@  @@@@@@@@  ".blue.bold)
    print("!@@       @@!  @@!  @@!  @@!  @@@  @@!@!@@@  @@!  @@@  ".blue.bold)
    print("!@!       !@!  !@!  !@!  !@!  @!@  !@!!@!@!  !@!  @!@  ".blue.bold)
    print("!!@@!!    @!!  !!@  @!@  @!@!@!@!  @!@ !!@!  @!@!@!@!  ".blue.bold)
    print(" !!@!!!   !@!  !!!  !@!  !!!@!!!!  !@!  !!!  !!!@!!!!  ".yellow.bold)
    print("     !:!  !!:  !!:  !!:  !!:  !!!  !!:  !!!  !!:  !!!  ".yellow.bold)
    print("    !:!   :!:  :!:  :!:  :!:  !:!  :!:  !:!  :!:  !:!  ".yellow.bold)
    print(":::: ::    :::: :: :::   ::   :::   ::   ::  ::   :::  ".yellow.bold)
    print(":: : :      :: :  : :     :   : :  ::    :    :   : :  ".yellow.bold)
    print("                                                       ".yellow.bold)

    let projectFolderURL = URL(fileURLWithPath: projectPath)

    let projectOverview = Parser.generateProjectOverview(at: projectFolderURL)
    Parser.printProjectOverview(projectOverview)
  }
}
