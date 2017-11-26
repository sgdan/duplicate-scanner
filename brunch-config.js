exports.paths = {
  public: 'web',
  watched: ['elm']
}

exports.files = {
  javascripts: {
  }
};

exports.plugins = {
  elmBrunch: {
    mainModules: ["elm/Main.elm"],
    outputFolder: "web/"
  }
};
