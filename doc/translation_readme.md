# Fab-manager translation documentation

This document will explain you what you need to know to contribute to the translation process of Fab-manager.

##### Table of contents

1. [Translation](#translation)<br/>
1.1. [Using a TMS](#using-a-tms)<br/>
1.2. [Using In-Context translation](#using-in-context-translation)<br/>
1.3. [From the files](#from-the-files)<br/>
1.3.1 [Front-end translations](#i18n-translation-front)<br/>
1.3.2 [Back-end translations](#i18n-translation-back)
2. [Configuration](#configuration)<br/>
2.1. [Settings](#settings)<br/>
2.2. [Applying changes](#applying-changes)

<a name="translation"></a>
## Translation

<a name="using-a-tms"></a>
### Using a TMS
We use [Crowdin](https://www.crowdin.com), a translation management system (TMS) to simplify translator's job in Fab-manager.
You can access it at [translate.fab-manager.com](https://translate.fab-manager.com) and start translating to one of the already configured languages.
If you want to translate Fab-manager to a new language, just send us an email to [contact@fab-manager.com](mailto:contact@fab-manager.com) and we'll add this new language to the TMS.

<a name="using-in-context-translation"></a>
### Using In-Context translation
To translate the front-end application (angularJS client), and the notifications, you can use [Crowdin In-Context](https://crowdin.com/page/in-context-localization).
This allows you to use Fab-manager as normally, but with the addition of small "edit" icons on the top-left corner of each text blocs.
Clicking on this "edit" icon will open the Crowdin translation interface and you'll be able to translate or modify existing translations directly.
You can access it at [in-context.translate.fab-manager.com](https://in-context.translate.fab-manager.com/).

<a name="from-the-files"></a>
### From the files
You **should not** translate Fab-manager from the source files, because it will conflict with the TMS.
Please refer to the [TMS method](#using-a-tms) for more details.

Nevertheless, **if you add a new feature** that requires some new translations, just add them to the english files.
You'll be able to provide translations for other languages later, using our TMS.

Moreover, if you want to improve the english texts, you'll need to modify the english files.

To add or edit the english translations, check the files located in `config/locales`:

- Front app translations (angular.js) are located in  `config/locales/app.SCOPE.en.yml`.
 Where SCOPE has one the following meaning :
    - admin: translations of the administrator views (manage and configure the FabLab).
    - logged: translations of the end-user's views accessible only to connected users.
    - public: translation of end-user's views publicly accessible to anyone.
    - shared: translations shared by many views (like forms or buttons).
- Back app translations (Ruby on Rails) are located in  `config/locales/en.yml`.
- Emails translations are located in `config/locales/mails.en.yml`.
- Messages related to the authentication system are located in `config/locales/devise.en.yml`.

To prevent syntax mistakes while translating locale files, we **STRONGLY advise** you to use a text editor which support syntax coloration for YML and Ruby.
As an example, [Visual Studio Code](https://code.visualstudio.com/), with the [Ruby extension](https://marketplace.visualstudio.com/items?itemName=rebornix.Ruby) and the [YAML extension](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) will do the job.

<a name="i18n-translation-front"></a>
#### Front-end translations

Front-end translations uses [angular-translate](http://angular-translate.github.io) with interpolations interpreted by [MessageFormat](https://github.com/SlexAxton/messageformat.js/).
**Please read the documentation about the [ICU MessageFormat syntax](http://userguide.icu-project.org/formatparse/messages#TOC-MessageFormat) before writing new strings.**

To translate existing strings, you should use our [translation management system](https://translate.fab-manager.com/).

<a name="i18n-translation-back"></a>
#### Back-end translations

Back-end translations uses the [Ruby on Rails syntax](http://guides.rubyonrails.org/i18n.html) but some complex interpolations are interpreted by [MessageFormat](https://github.com/format-message/message-format-rb) and are marked as it in comments.
**DO NOT confuse the syntaxes.**

In each cases, some inline comments are included in the localisation files.
They can be recognized as they start with the sharp character (#).
These comments are not required to be translated, they are intended to help the translator to have some context information about the sentence to translate.

You will also need to translate the invoice watermark, located in `app/pdfs/data/`.
You'll find there the [GIMP source of the image](app/pdfs/data/watermark.xcf), which is using [Rubik Mono One](https://fonts.google.com/specimen/Rubik+Mono+One) as font.
Use it to generate a similar localised PNG image which keep the default image size, as PDF are not responsive.

Also, please create a [base.LOCALE.yml](../config/locales/base.en.yml) and fill it with the time-only format in use in your locale.

Finally, add your new locale and its derivatives to the `available_locales` array in [initializers/locale.rb](../config/initializers/locale.rb) to make it available in Fab-manager.

<a name="configuration"></a>
## Configuration

In development, locales configurations are made in [.env](../env.example).
In production, locales configuration are made in the [config/env](../setup/env.example) file.
If you are in a development environment, your can keep the default values, otherwise, in production, values must be configured carefully.

<a name="settings"></a>
### Settings

Please refer to the [environment configuration documentation](environment.md#internationalization-settings)

<a name="applying-changes"></a>
### Applying changes

After modifying any values concerning the localisation, restart the application (ie. web server) to apply these changes in the i18n configuration.
