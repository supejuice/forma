# Forma

Forma is a Calorie Tracker app designed to utlise AI chat completions as your backend service.

## Features

- Flutter app: multi platform
- Genkit CLI
- Mistral apis support

## Installation

To install and set up the project, follow these steps:

```zsh
git clone https://github.com/yourusername/forma.git
# if you haven't installed node
cd forma
brew update
brew install node
node -v
npm -v
# genkit node modules
npm i genkit
npm i genkit-cli 
npx genkit init
# go packages
go get github.com/firebase/genkit/go/core
go get github.com/firebase/genkit/go/genkit
go get github.com/firebase/genkit/go/plugins/server
```
Finally, add your gemini api key to shell profile:
export GEMINI_API_KEY=<YOUR_KEY>

## Usage

```zsh
# Example usage
npx genkit start go run main.go
```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-name`).
3. Commit your changes (`git commit -m 'Add feature'`).
4. Push to the branch (`git push origin feature-name`).
5. Open a pull request.

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](https://github.com/supejuice/forma/blob/main/LICENSE) file for details.

## Contact

For questions or feedback, please contact [sysalchemist@hotmail.com].