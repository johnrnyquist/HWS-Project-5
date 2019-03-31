import UIKit

class ViewController: UITableViewController {
    
    var allWords = [String]()
    var usedWords = [String]()
    
    
    func save() {
        let defaults = UserDefaults.standard
        defaults.set(usedWords, forKey: "usedWords")
        defaults.set(allWords, forKey: "allWords")
        defaults.set(title!, forKey: "title")
    }
    
    func load() {
        let defaults = UserDefaults.standard
        usedWords = defaults.object(forKey: "usedWords") as? [String] ?? [String]()
        allWords = defaults.object(forKey: "allWords") as? [String] ?? [String]()
        title = defaults.string(forKey: "title") ?? "Error"
    }
    

    
    //MARK: - UIViewController Class
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(promptForAnswer))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh,
                                                           target: self,
                                                           action: #selector(startGame))
        load()
        if allWords.count == 0 {
            loadDefaultWords()
            startGame()
        } else {
            continueGame()
        }
    }

    func continueGame() {
        tableView.reloadData()
    }
    
    
    //MARK: - UITableViewDataSource Protocol
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = usedWords[indexPath.row]
        return cell
    }
    
    
    //MARK: - ViewController
    
    func loadDefaultWords() {
        guard let startWordsPath  = Bundle.main.path(forResource: "start", ofType: "txt") else { return }
        guard let startWords =  try? String(contentsOfFile: startWordsPath) else { return }
        guard startWords.count > 0 else { return }
        allWords = startWords.components(separatedBy: "\n")
    }

    @objc func startGame() {
        title = allWords.randomElement()
        usedWords.removeAll(keepingCapacity: true)
        save()
        tableView.reloadData()
    }
    
    func submit(answer: String) {
        let lowerAnswer = answer.lowercased()
        
        guard lowerAnswer != title?.lowercased() else {
            showErrorMessage(title: "Same word",
                             message: "Too easy, don't use the same word!")
            return
        }
        guard isLongEnough(word: lowerAnswer) else {
            showErrorMessage(title: "Word not long enough",
                             message: "Let's keep this to four letter words or greater!")
            return
        }
        guard isPossible(word: lowerAnswer) else {
            showErrorMessage(title: "Word not possible",
                             message: "You can't spell that word from '\(title!.lowercased())'!")
            return
        }
        guard isOriginal(word: lowerAnswer) else {
            showErrorMessage(title: "Word used already",
                             message: "Be more original!")
            return
        }
        guard isReal(word: lowerAnswer) else {
            showErrorMessage(title: "Word not recognized",
                             message: "You can't just make them up!")
            return
        }
        
        usedWords.insert(answer, at: 0)
        save()
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    func showErrorMessage(title errorTitle: String, message errorMessage: String){
        let ac = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    func isLongEnough(word: String) -> Bool {
       return word.count > 3
    }
    
    func isPossible(word: String) -> Bool {
        var tempWord = title!.lowercased()
        
        for letter in word {
            if let pos = tempWord.range(of: String(letter)) {
                tempWord.remove(at: pos.lowerBound)
            } else {
                return false
            }
        }
        
        return true
    }
    
    func isOriginal(word: String) -> Bool {
        return !usedWords.contains(word)
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSMakeRange(0, word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    
    //MARK: - #selector
    
    @objc func promptForAnswer() {
        let ac = UIAlertController(title: "Enter answer", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned self, ac] _ in
            let answer = ac.textFields![0]
            self.submit(answer: answer.text!)
        }
        
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
}
