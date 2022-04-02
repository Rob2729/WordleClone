import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject var wordle = WordleModel()
    var body: some View {
        wordleGame()
            .environmentObject(wordle)
    }
}



struct wordleGame : View {
    @EnvironmentObject var dm : WordleModel
    var body: some View {
        NavigationView {
            
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    VStack(spacing: 3) {
                        ForEach(0...5, id: \.self) { index in
                            GuessView(guess: $dm.guesses[index])
                            
                        }
                    }
                    .frame(width: 275, height: 320)
                    Keyboard()
                        .scaleEffect(0.8)
                        .padding(.bottom)
                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack (spacing: 1) {
                            Button {
                                
                            } label : {
                                Image(systemName: "line.3.horizontal")
                            }
                            Button {
                                
                            } label : {
                                Image(systemName: "questionmark.circle")
                            }
                        }
                        .foregroundColor(.white)
                        
                    }
                    ToolbarItem(placement: .principal) {
                        Text("Wordle")
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 2) {
                            Button {
                                
                            } label: {
                                Image(systemName: "chart.bar")
                            }
                            
                            Button {
                                
                            } label : {
                                Image(systemName: "gear")
                            }
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct Guess { 
    let index:Int
    var word = "     "
    var bgColors = [Color](repeating: .gray, count: 5)
    var letterFlipped = [Bool](repeating: false, count: 5)
    var guessLetters : [String] {
        word.map{String($0)}
    }
}

struct GuessView : View {
    @Binding var guess : Guess
    var body : some View {
        HStack (spacing: 3) { 
            ForEach(0...4, id: \.self) { index in
                Text(guess.guessLetters[index])
                    .foregroundColor(.primary)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: 35, weight: .heavy))
                    .background(guess.bgColors[index])
                    .border(Color.secondary)
            }
        }
    }
}

class WordleModel : ObservableObject {
    @Published var guesses : [Guess] = []
    @Published var incorrectAttemps = [Int](repeating: 0, count: 6)
    let wordChoices : [String] = ["ALLOW", "THEIR", "TREAT"]
    
    var keyColours = [String : Color] ()
    var matchedLetter = [String]()
    var misplacedLetters = [String]()
    var selectedWord = ""
    var currentWord = ""
    var tryIndex = 0
    var inPlay = false
    var gameOver = false
    
    var gameStarted : Bool {
        !currentWord.isEmpty || tryIndex > 0
    }
    
    var disabledKeys : Bool {
        !inPlay || currentWord.count == 5
    }
    
    init() {
        newGame()
    }
    
    func newGame() {
        populateDefaults()
        selectedWord = wordChoices.randomElement()!
        currentWord = ""
        inPlay = true
    }
    
    func populateDefaults() {
        guesses = []
        for index in 0...5 {
            guesses.append(Guess(index: index))
        }
        //reset keyboard colors
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for char in letters {
            keyColours[String(char)] = .gray
        }
        matchedLetter = []
        misplacedLetters = []
    }
    
    func addToCurrentWord(_ letter: String) {
        currentWord += letter
        updateRow()
    }
    
    func enterWord(){
        if currentWord == selectedWord {
            setCurrentGuessColours()
            gameOver = true
            print("You Win!")
            inPlay = false
        } else {
            if(verifyWord()) {
                print("Valid word")
                setCurrentGuessColours()
                tryIndex += 1
                currentWord = ""
                if tryIndex == 6 {
                    gameOver = true
                    inPlay = false
                    print("You Lose")
                }
            } else {
                self.incorrectAttemps[tryIndex] += 1
                incorrectAttemps[tryIndex] = 0
            }
        }
        
    }
    
    func removeLetterFromCurrentWord() {
        currentWord.removeLast()
        updateRow()
    }
    
    func updateRow() {
        let guessWord = currentWord.padding(toLength: 5, withPad: " ", startingAt: 0)
        guesses[tryIndex].word = guessWord
    }
    
    func verifyWord() -> Bool {
        UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: currentWord)
    }
    
    func setCurrentGuessColours() {
        let correctLetters = selectedWord.map { String($0)}
        var frequency = [String : Int]()
        for letter in correctLetters {
            frequency[letter, default: 0] += 1
        }
        
        for index in 0...4 {
            let correctLetter = correctLetters[index]
            let guessLetter = guesses[tryIndex].guessLetters[index]
            print("\(index) \(guessLetter) ")
            print("\(index) \(correctLetter) ")
            if guessLetter == correctLetter {
                guesses[tryIndex].bgColors[index] = .correct
                if !matchedLetter.contains(guessLetter) {
                    matchedLetter.append(guessLetter)
                    keyColours[guessLetter] = .correct
                }
                if(misplacedLetters.contains(guessLetter)) {
                    if let index = misplacedLetters.firstIndex(where: {$0 == guessLetter}) {
                        misplacedLetters.remove(at: index)
                    }
                }
                frequency[guessLetter]! -= 1
            }
        }
        
        for index in 0...4 {
            let guessLetter = guesses[tryIndex].guessLetters[index]
            if correctLetters.contains(guessLetter) && guesses[tryIndex].bgColors[index] != .correct && frequency[guessLetter]! > 0 {
                guesses[tryIndex].bgColors[index] = .misplaced
                if !misplacedLetters.contains(guessLetter) && !matchedLetter.contains(guessLetter) {
                    misplacedLetters.append(guessLetter)
                    keyColours[guessLetter] = .misplaced
                }
                frequency[guessLetter]! -= 1
            }
        }
        
        for index in 0...4 {
            let guessLetter = guesses[tryIndex].guessLetters[index]
            if (keyColours[guessLetter] != .correct && keyColours[guessLetter] != .misplaced) {
                keyColours[guessLetter] = .wrong
            }
        }
    }
}

struct Keyboard : View {
    @EnvironmentObject var dm : WordleModel
    var topRowArray = "QWERTYUIOP".map{String($0)}
    var secondRowArray = "ASDFGHJKL".map{ String($0)}
    var thirdRowArray = "ZXCVBNM".map{ String ($0)}
    var body: some View {
        VStack {
            HStack(spacing: 2) {
                ForEach(topRowArray, id: \.self) { letter in
                    LetterButtonView(letter: letter)
                    
                }
                .disabled(dm.disabledKeys)
                .opacity(dm.disabledKeys ? 0.6 : 1)
            }
            HStack(spacing: 2) {
                ForEach(secondRowArray, id: \.self) { letter in
                    LetterButtonView(letter: letter)
                    
                }
                .disabled(dm.disabledKeys)
                .opacity(dm.disabledKeys ? 0.6 : 1)
            }
            HStack(spacing: 2) {
                Button {
                    dm.enterWord()
                } label : {
                    Text("Enter")
                }
                .font(.system(size: 20))
                .frame(width:60, height: 50)
                .foregroundColor(.primary)
                .background(Color.unsued)
                .disabled(dm.currentWord.count < 5 || !dm.inPlay)
                .opacity((dm.currentWord.count < 5 || !dm.inPlay) ? 0.6 : 1)
                ForEach(thirdRowArray, id: \.self) { letter in
                    LetterButtonView(letter: letter)
                    
                }
                .disabled(dm.disabledKeys)
                .opacity(dm.disabledKeys ? 0.6 : 1)
                Button {
                    dm.removeLetterFromCurrentWord()
                } label : {
                    Image(systemName: "delete.backward.fill")
                        .font(.system(size: 20))
                        .frame(width:60, height: 50)
                        .foregroundColor(.primary)
                        .background(Color.unsued)
                }
                .disabled(!dm.inPlay || dm.currentWord.count == 0)
                .opacity((!dm.inPlay || dm.currentWord.count == 0) ? 0.6 : 1)
            }
        }
    }
}

struct LetterButtonView : View {
    @EnvironmentObject var dm : WordleModel
    var letter : String
    var body : some View {
        Button {
            dm.addToCurrentWord(letter)
        } label : {
            Text(letter)
                .font(.system(size: 20))
                .frame(width: 35, height: 50)
                .background(dm.keyColours[letter])
                .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }
}

enum Global {
    static var screenWidth : CGFloat {
        UIScreen.main.bounds.size.width
    }
    
    static var screenHeight : CGFloat {
        UIScreen.main.bounds.size.height
    }
    
    static var minDimensions : CGFloat {
        min(screenWidth, screenHeight)
    }
}

extension Color {
    static var wrong : Color {
        .red
    }
    static var misplaced : Color {
        .orange
    }
    
    static var correct : Color {
        .green
    }
    
    static var unsued : Color {
        .gray
    }
    
    static var background : Color {
        .yellow
    }
}
