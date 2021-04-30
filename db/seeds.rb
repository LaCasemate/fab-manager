
if StatisticIndex.count.zero?
  StatisticIndex.create!([
                           { id: 1, es_type_key: 'subscription', label: I18n.t('statistics.subscriptions') },
                           { id: 2, es_type_key: 'machine', label: I18n.t('statistics.machines_hours') },
                           { id: 3, es_type_key: 'training', label: I18n.t('statistics.trainings') },
                           { id: 4, es_type_key: 'event', label: I18n.t('statistics.events') },
                           { id: 5, es_type_key: 'account', label: I18n.t('statistics.registrations'), ca: false },
                           { id: 6, es_type_key: 'project', label: I18n.t('statistics.projects'), ca: false },
                           { id: 7, es_type_key: 'user', label: I18n.t('statistics.users'), table: false, ca: false }
                         ])
  connection = ActiveRecord::Base.connection
  connection.execute("SELECT setval('statistic_indices_id_seq', 7);") if connection.instance_values['config'][:adapter] == 'postgresql'
end

if StatisticField.count.zero?
  StatisticField.create!([
                           # available data_types : index, number, date, text, list
                           { key: 'trainingId', label: I18n.t('statistics.training_id'), statistic_index_id: 3, data_type: 'index' },
                           { key: 'trainingDate', label: I18n.t('statistics.training_date'), statistic_index_id: 3, data_type: 'date' },
                           { key: 'eventId', label: I18n.t('statistics.event_id'), statistic_index_id: 4, data_type: 'index' },
                           { key: 'eventDate', label: I18n.t('statistics.event_date'), statistic_index_id: 4, data_type: 'date' },
                           { key: 'themes', label: I18n.t('statistics.themes'), statistic_index_id: 6, data_type: 'list' },
                           { key: 'components', label: I18n.t('statistics.components'), statistic_index_id: 6, data_type: 'list' },
                           { key: 'machines', label: I18n.t('statistics.machines'), statistic_index_id: 6, data_type: 'list' },
                           { key: 'name', label: I18n.t('statistics.event_name'), statistic_index_id: 4, data_type: 'text' },
                           { key: 'userId', label: I18n.t('statistics.user_id'), statistic_index_id: 7, data_type: 'index' },
                           { key: 'eventTheme', label: I18n.t('statistics.event_theme'), statistic_index_id: 4, data_type: 'text' },
                           { key: 'ageRange', label: I18n.t('statistics.age_range'), statistic_index_id: 4, data_type: 'text' }
                         ])
end

unless StatisticField.find_by(key: 'groupName').try(:label)
  field = StatisticField.find_or_initialize_by(key: 'groupName')
  field.label = 'Groupe'
  field.statistic_index_id = 1
  field.data_type = 'text'
  field.save!
end

if StatisticType.count.zero?
  StatisticType.create!([
                          { statistic_index_id: 2, key: 'booking', label: I18n.t('statistics.bookings'), graph: true, simple: true },
                          { statistic_index_id: 2, key: 'hour', label: I18n.t('statistics.hours_number'), graph: true, simple: false },
                          { statistic_index_id: 3, key: 'booking', label: I18n.t('statistics.bookings'), graph: false, simple: true },
                          { statistic_index_id: 3, key: 'hour', label: I18n.t('statistics.hours_number'), graph: false, simple: false },
                          { statistic_index_id: 4, key: 'booking', label: I18n.t('statistics.tickets_number'), graph: false,
                            simple: false },
                          { statistic_index_id: 4, key: 'hour', label: I18n.t('statistics.hours_number'), graph: false, simple: false },
                          { statistic_index_id: 5, key: 'member', label: I18n.t('statistics.users'), graph: true, simple: true },
                          { statistic_index_id: 6, key: 'project', label: I18n.t('statistics.projects'), graph: false, simple: true },
                          { statistic_index_id: 7, key: 'revenue', label: I18n.t('statistics.revenue'), graph: false, simple: false }
                        ])
end

if StatisticSubType.count.zero?
  StatisticSubType.create!([
                             { key: 'created', label: I18n.t('statistics.account_creation'),
                               statistic_types: StatisticIndex.find_by(es_type_key: 'account').statistic_types },
                             { key: 'published', label: I18n.t('statistics.project_publication'),
                               statistic_types: StatisticIndex.find_by(es_type_key: 'project').statistic_types }
                           ])
end

if StatisticGraph.count.zero?
  StatisticGraph.create!([
                           { statistic_index_id: 1, chart_type: 'stackedAreaChart', limit: 0 },
                           { statistic_index_id: 2, chart_type: 'stackedAreaChart', limit: 0 },
                           { statistic_index_id: 3, chart_type: 'discreteBarChart', limit: 10 },
                           { statistic_index_id: 4, chart_type: 'discreteBarChart', limit: 10 },
                           { statistic_index_id: 5, chart_type: 'lineChart', limit: 0 },
                           { statistic_index_id: 7, chart_type: 'discreteBarChart', limit: 10 }
                         ])
end

if Group.count.zero?
  Group.create!([
                  { name: 'standard, association', slug: 'standard' },
                  { name: "étudiant, - de 25 ans, enseignant, demandeur d'emploi", slug: 'student' },
                  { name: 'artisan, commerçant, chercheur, auto-entrepreneur', slug: 'merchant' },
                  { name: 'PME, PMI, SARL, SA', slug: 'business' }
                ])
end

Group.create! name: I18n.t('group.admins'), slug: 'admins' unless Group.find_by(slug: 'admins')

# Create the default admin if none exists yet
if Role.where(name: 'admin').joins(:users).count.zero?
  admin = User.new(username: 'admin', email: ENV['ADMIN_EMAIL'], password: ENV['ADMIN_PASSWORD'],
                   password_confirmation: Rails.application.secrets.admin_password, group_id: Group.find_by(slug: 'admins').id,
                   profile_attributes: { first_name: 'admin', last_name: 'admin', phone: '0123456789' },
                   statistic_profile_attributes: { gender: true, birthday: DateTime.current })
  admin.add_role 'admin'
  admin.save!
end

if Component.count.zero?
  Component.create!([
                      { name: 'Silicone' },
                      { name: 'Vinyle' },
                      { name: 'Bois Contre plaqué' },
                      { name: 'Bois Medium' },
                      { name: 'Plexi / PMMA' },
                      { name: 'Flex' },
                      { name: 'Vinyle' },
                      { name: 'Parafine' },
                      { name: 'Fibre de verre' },
                      { name: 'Résine' }
                    ])
end

if Licence.count.zero?
  Licence.create!([
                    { name: 'Attribution (BY)', description: 'Le titulaire des droits autorise toute exploitation de l’œuvre, y compris à' \
                      ' des fins commerciales, ainsi que la création d’œuvres dérivées, dont la distribution est également autorisé sans ' \
                      'restriction, à condition de l’attribuer à son l’auteur en citant son nom. Cette licence est recommandée pour la ' \
                      'diffusion et l’utilisation maximale des œuvres.' },
                    { name: 'Attribution + Pas de modification (BY ND)', description: 'Le titulaire des droits autorise toute utilisation' \
                      ' de l’œuvre originale (y compris à des fins commerciales), mais n’autorise pas la création d’œuvres dérivées.' },
                    { name: "Attribution + Pas d'Utilisation Commerciale + Pas de Modification (BY NC ND)", description: 'Le titulaire ' \
                      'des droits autorise l’utilisation de l’œuvre originale à des fins non commerciales, mais n’autorise pas la ' \
                      'création d’œuvres dérivés.' },
                    { name: "Attribution + Pas d'Utilisation Commerciale (BY NC)", description: 'Le titulaire des droits autorise ' \
                      'l’exploitation de l’œuvre, ainsi que la création d’œuvres dérivées, à condition qu’il ne s’agisse pas d’une ' \
                      'utilisation commerciale (les utilisations commerciales restant soumises à son autorisation).' },
                    { name: "Attribution + Pas d'Utilisation Commerciale + Partage dans les mêmes conditions (BY NC SA)", description:
                      'Le titulaire des droits autorise l’exploitation de l’œuvre originale à des fins non commerciales, ainsi que la ' \
                      'création d’œuvres dérivées, à condition qu’elles soient distribuées sous une licence identique à celle qui régit ' \
                      'l’œuvre originale.' },
                    { name: 'Attribution + Partage dans les mêmes conditions (BY SA)', description: 'Le titulaire des droits autorise ' \
                      'toute utilisation de l’œuvre originale (y compris à des fins commerciales) ainsi que la création d’œuvres dérivées' \
                      ', à condition qu’elles soient distribuées sous une licence identique à celle qui régit l’œuvre originale. Cette' \
                      'licence est souvent comparée aux licences « copyleft » des logiciels libres. C’est la licence utilisée par ' \
                      'Wikipedia.' }
                  ])
end

if Theme.count.zero?
  Theme.create!([
                  { name: 'Vie quotidienne' },
                  { name: 'Robotique' },
                  { name: 'Arduine' },
                  { name: 'Capteurs' },
                  { name: 'Musique' },
                  { name: 'Sport' },
                  { name: 'Autre' }
                ])
end

if Training.count.zero?
  Training.create!([
                     { name: 'Formation Imprimante 3D', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do ' \
                       'eiusmod tempor incididunt ut labore et dolore magna aliqua.' },
                     { name: 'Formation Laser / Vinyle', description: 'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris' \
                       ' nisi ut aliquip ex ea commodo consequat.' },
                     { name: 'Formation Petite fraiseuse numerique', description: 'Duis aute irure dolor in reprehenderit in voluptate ' \
                       'velit esse cillum dolore eu fugiat nulla pariatur.' },
                     { name: 'Formation Shopbot Grande Fraiseuse', description: 'Excepteur sint occaecat cupidatat non proident, sunt in ' \
                       'culpa qui officia deserunt mollit anim id est laborum.' },
                     { name: 'Formation logiciel 2D', description: 'Sed ut perspiciatis unde omnis iste natus error sit voluptatem ' \
                       'accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi ' \
                       'architecto beatae vitae dicta sunt explicabo.' }
                   ])

  TrainingsPricing.all.each do |p|
    p.update_columns(amount: (rand * 50 + 5).floor * 100)
  end
end

if Machine.count.zero?
  Machine.create!([
                    { name: 'Découpeuse laser', description: "Préparation à l'utilisation de l'EPILOG Legend 36EXT\r\nInformations" \
                      " générales    \r\n      Pour la découpe, il suffit d'apporter votre fichier vectorisé type illustrator, svg ou dxf" \
                      " avec des \"lignes de coupe\" d'une épaisseur inférieur à 0,01 mm et la machine s'occupera du reste!\r\n     La " \
                      'gravure est basée sur le spectre noir et blanc. Les nuances sont obtenues par différentes profondeurs de gravure ' \
                      "correspondant aux niveaux de gris de votre image. Il suffit pour cela d'apporter une image scannée ou un fichier " \
                      "photo en noir et blanc pour pouvoir reproduire celle-ci sur votre support! \r\nQuels types de matériaux pouvons " \
                      "nous graver/découper?\r\n     Du bois au tissu, du plexiglass au cuir, cette machine permet de découper et graver " \
                      "la plupart des matériaux sauf les métaux. La gravure est néanmoins possible sur les métaux recouverts d'une couche" \
                      " de peinture ou les aluminiums anodisés. \r\n        Concernant l'épaisseur des matériaux découpés, il est " \
                      "préférable de ne pas dépasser 5 mm pour le bois et 6 mm pour le plexiglass.\r\n", spec: "Puissance: 40W\r\nSurface" \
                      " de travail: 914x609 mm \r\nEpaisseur maximale de la matière: 305mm\r\nSource laser: tube laser type CO2\r\n" \
                      'Contrôles de vitesse et de puissance: ces deux paramètres sont ajustables en fonction du matériau (de 1% à 100%) .' \
                      "\r\n", slug: 'decoupeuse-laser' },
                    { name: 'Découpeuse vinyle', description: "Préparation à l'utilisation de la Roland CAMM-1 GX24\r\nInformations " \
                      "générales        \r\n     Envie de réaliser un tee shirt personnalisé ? Un sticker à l'effigie votre groupe " \
                      "préféré ? Un masque pour la réalisation d'un circuit imprimé? Pour cela, il suffit simplement de venir avec votre" \
                      " fichier vectorisé (ne pas oublier de vectoriser les textes) type illustrator svg ou dxf.\r\n \r\nMatériaux " \
                      "utilisés:\r\n    Cette machine permet de découper principalement du vinyle,vinyle réfléchissant, flex.\r\n",
                      spec: "Largeurs de support acceptées: de 50 mm à 700 mm\r\nVitesse de découpe: 50 cm/sec\r\nRésolution mécanique: " \
                      "0,0125 mm/pas\r\n", slug: 'decoupeuse-vinyle' },
                    { name: 'Shopbot / Grande fraiseuse', description: "La fraiseuse numérique ShopBot PRS standard\r\nInformations " \
                      "générales\r\nCette machine est un fraiseuse 3 axes idéale pour l'usinage de pièces de grandes dimensions. De la " \
                      "réalisation d'une chaise ou d'un meuble jusqu'à la construction d'une maison ou d'un assemblage immense, le " \
                      "ShopBot ouvre de nombreuses portes à votre imagination! \r\nMatériaux usinables\r\nLes principaux matériaux " \
                      "usinables sont le bois, le plastique, le laiton et bien d'autres.\r\nCette machine n'usine pas les métaux.\r\n",
                      spec: "Surface maximale de travail: 2440x1220x150 (Z) mm\r\nLogiciel utilisé: Partworks 2D & 3D\r\nRésolution " \
                      "mécanique: 0,015 mm\r\nPrécision de la position: +/- 0,127mm\r\nFormats acceptés: DXF, STL \r\n",
                      slug: 'shopbot-grande-fraiseuse' },
                    { name: 'Imprimante 3D', description: "L'utimaker est une imprimante 3D  low cost utilisant une technologie FFF " \
                      "(Fused Filament Fabrication) avec extrusion thermoplastique.\r\nC'est une machine idéale pour réaliser rapidement " \
                      "des prototypes 3D dans des couleurs différentes.\r\n", spec: "Surface maximale de travail: 210x210x220mm \r\n" \
                      "Résolution méchanique: 0,02 mm \r\nPrécision de position: +/- 0,05 \r\nLogiciel utilisé: Cura\r\nFormats de " \
                      "fichier acceptés: STL \r\nMatériaux utilisés: PLA (en stock).", slug: 'imprimante-3d' },
                    { name: 'Petite Fraiseuse', description: "La fraiseuse numérique Roland Modela MDX-20\r\nInformations générales" \
                      "\r\nCette machine est utilisée  pour l'usinage et le scannage 3D de précision. Elle permet principalement d'usiner" \
                      ' des circuits imprimés et des moules de petite taille. Le faible diamètre des fraises utilisées (Ø 0,3 mm à  Ø 6mm' \
                      ") induit que certains temps d'usinages peuvent êtres long (> 12h), c'est pourquoi cette fraiseuse peut être " \
                      "laissée en autonomie toute une nuit afin d'obtenir le plus précis des usinages au FabLab.\r\nMatériaux usinables:" \
                      "\r\nLes principaux matériaux usinables sont le bois, plâtre, résine, cire usinable, cuivre.\r\n",
                      spec: "Taille du plateau X/Y : 220 mm x 160 mm\r\nVolume maximal de travail: 203,2 mm (X), 152,4 mm (Y), 60,5 mm " \
                      "(Z)\r\nPrécision usinage: 0,00625 mm\r\nPrécision scannage: réglable de 0,05 à 5 mm (axes X,Y) et 0,025 mm (axe Z)" \
                      "\r\nVitesse d'analyse (scannage): 4-15 mm/sec\r\n \r\n \r\nLogiciel utilisé pour le fraisage: Roland Modela player" \
                      " 4 \r\nLogiciel utilisé pour l'usinage de circuits imprimés: Cad.py (linux)\r\nFormats acceptés: STL,PNG 3D\r\n" \
                      "Format d'exportation des données scannées: DXF, VRML, STL, 3DMF, IGES, Grayscale, Point Group et BMP\r\n",
                      slug: 'petite-fraiseuse' }
                  ])

  Price.all.each do |p|
    p.update_columns(amount: (rand * 50 + 5).floor * 100)
  end
end

if Category.count.zero?
  Category.create!(
    [
      { name: 'Stage' },
      { name: 'Atelier' }
    ]
  )
end

unless Setting.find_by(name: 'about_body').try(:value)
  setting = Setting.find_or_initialize_by(name: 'about_body')
  setting.value = <<~HTML
    <p>
      <a href="http://fab-manager.com" target="_blank">Fab-manager</a> est outil de gestion des atelier de fabrication
      numérique, permettant de réserver des machines de découpe, des imprimantes 3D, etc. tout en gérant simplement
      les aspect financier, comptable et statistiques de votre espace.
    </p>
    <p>
      <a href="http://fab-manager.com" target="_blank">Fab-manager</a> est un projet libre : ouvert à tous, il offre la
      possibilité de contribuer soi-même au code, de télécharger le logiciel, de l'étudier et de le redistribuer. Vous
      n'êtes pas technicien ? Vous pouvez quand même participer à <a href="https://translate.fab-manager.com/">traduire
      Fab-manager dans votre langue</a>.
    </p>
    <p>
      Fab-manager favorise le partage de connaissances grâce au réseau OpenLab : les projets que vous documentez sont
      partagés avec l'ensemble du réseau des Fab-managers.
    </p>
  HTML
  setting.save
end

Setting.set('about_title', 'Imaginer, Fabriquer, <br>Partager avec Fab-manager') unless Setting.find_by(name: 'about_title').try(:value)

unless Setting.find_by(name: 'about_contacts').try(:value)
  setting = Setting.find_or_initialize_by(name: 'about_contacts')
  setting.value = <<~HTML
    <dl>
    <dt>Support technique :</dt>
    <dd><a href="https://forum.fab-manager.com">Forum</a></dd>
    <dd><a href="https://feedback.fab-manager.com">Feedback</a></dd>
    <dd><a href="https://github.com/sleede/fab-manager/">GitHub</a></dd>
    </dl>
    <br><br>
    <p><a href='http://fab-manager.com'>Visitez le site de Fab-manager</a></p>
  HTML
  setting.save
end

Setting.set('twitter_name', 'Fab_Manager') unless Setting.find_by(name: 'twitter_name').try(:value)

unless Setting.find_by(name: 'machine_explications_alert').try(:value)
  setting = Setting.find_or_initialize_by(name: 'machine_explications_alert')
  setting.value = 'Tout achat de créneau machine est définitif. Aucune' \
  ' annulation ne pourra être effectuée, néanmoins au plus tard 24h avant le créneau fixé, vous pouvez en' \
  " modifier la date et l'horaire à votre convenance et en fonction du calendrier proposé. Passé ce délais," \
  ' aucun changement ne pourra être effectué.'
  setting.save
end

unless Setting.find_by(name: 'training_explications_alert').try(:value)
  setting = Setting.find_or_initialize_by(name: 'training_explications_alert')
  setting.value = 'Toute réservation de formation est définitive.' \
  ' Aucune annulation ne pourra être effectuée, néanmoins au plus tard 24h avant le créneau fixé, vous pouvez' \
  " en modifier la date et l'horaire à votre convenance et en fonction du calendrier proposé. Passé ce délais," \
  ' aucun changement ne pourra être effectué.'
  setting.save
end

unless Setting.find_by(name: 'subscription_explications_alert').try(:value)
  setting = Setting.find_or_initialize_by(name: 'subscription_explications_alert')
  setting.value = <<~HTML
    <p><b>Règle sur la date de début des abonnements</b></p>
    <ul>
    <li><span style=\"font-size: 1.6rem; line-height: 2.4rem;\">Si vous êtes un nouvel utilisateur - i.e aucune
    formation d'enregistrée sur le site - votre abonnement débutera à la date de réservation de votre première
    formation.</span></li>
    <li><span style="font-size: 1.6rem; line-height: 2.4rem;">Si vous avez déjà une formation ou plus de validée,
    votre abonnement débutera à la date de votre achat d'abonnement.</span></li>
    </ul>
    <p>Merci de bien prendre ses informations en compte, et merci de votre compréhension. L'équipe du Fab Lab.<br>
    </p>
  HTML
  setting.save
end

unless Setting.find_by(name: 'invoice_logo').try(:value)
  setting = Setting.find_or_initialize_by(name: 'invoice_logo')
  setting.value = <<~BASE64
    iVBORw0KGgoAAAANSUhEUgAAAG0AAABZCAYAAAA0E6rtAAAACXBIWXMAAAsTAAALEwEAmpwYAAA57WlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94
    cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIg
    eDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxMzggNzkuMTU5ODI0LCAyMDE2LzA5LzE0LTAxOjA5OjAxICAgICAgICAiPgogICA8cmRmOlJERiB4
    bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91
    dD0iIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOmRjPSJodHRwOi8v
    cHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIKICAgICAgICAgICAgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8x
    LjAvIgogICAgICAgICAgICB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIKICAgICAgICAgICAgeG1sbnM6c3RFdnQ9
    Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFk
    b2JlLmNvbS90aWZmLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIj4KICAgICAgICAgPHht
    cDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ0MgMjAxNyAoV2luZG93cyk8L3htcDpDcmVhdG9yVG9vbD4KICAgICAgICAgPHhtcDpDcmVhdGVE
    YXRlPjIwMTctMDEtMDNUMTE6MTg6MTgrMDE6MDA8L3htcDpDcmVhdGVEYXRlPgogICAgICAgICA8eG1wOk1vZGlmeURhdGU+MjAxNy0wNi0wNlQxNTo1
    NjoxMiswMjowMDwveG1wOk1vZGlmeURhdGU+CiAgICAgICAgIDx4bXA6TWV0YWRhdGFEYXRlPjIwMTctMDYtMDZUMTU6NTY6MTIrMDI6MDA8L3htcDpN
    ZXRhZGF0YURhdGU+CiAgICAgICAgIDxkYzpmb3JtYXQ+aW1hZ2UvcG5nPC9kYzpmb3JtYXQ+CiAgICAgICAgIDxwaG90b3Nob3A6Q29sb3JNb2RlPjM8
    L3Bob3Rvc2hvcDpDb2xvck1vZGU+CiAgICAgICAgIDx4bXBNTTpJbnN0YW5jZUlEPnhtcC5paWQ6MmYwMTE5MTMtODI5NS0zOTQ0LWJmZjYtMTY5ZTNh
    ZTQ5OThlPC94bXBNTTpJbnN0YW5jZUlEPgogICAgICAgICA8eG1wTU06RG9jdW1lbnRJRD5hZG9iZTpkb2NpZDpwaG90b3Nob3A6ZGU3ZGE1MmYtNGFi
    Zi0xMWU3LTljODAtYWJjY2ZlM2JkNzdmPC94bXBNTTpEb2N1bWVudElEPgogICAgICAgICA8eG1wTU06T3JpZ2luYWxEb2N1bWVudElEPnhtcC5kaWQ6
    YTE5NTAzOTAtOGQwOS0zMzQ3LWFkNGQtMzkyNDQ2YjRiNWJiPC94bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ+CiAgICAgICAgIDx4bXBNTTpIaXN0b3J5
    PgogICAgICAgICAgICA8cmRmOlNlcT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAg
    ICAgIDxzdEV2dDphY3Rpb24+Y3JlYXRlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6aW5zdGFuY2VJRD54bXAuaWlkOmEx
    OTUwMzkwLThkMDktMzM0Ny1hZDRkLTM5MjQ0NmI0YjViYjwvc3RFdnQ6aW5zdGFuY2VJRD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OndoZW4+MjAx
    Ny0wMS0wM1QxMToxODoxOCswMTowMDwvc3RFdnQ6d2hlbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OnNvZnR3YXJlQWdlbnQ+QWRvYmUgUGhvdG9z
    aG9wIENDIDIwMTcgKFdpbmRvd3MpPC9zdEV2dDpzb2Z0d2FyZUFnZW50PgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJk
    ZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+c2F2ZWQ8L3N0RXZ0OmFjdGlvbj4KICAg
    ICAgICAgICAgICAgICAgPHN0RXZ0Omluc3RhbmNlSUQ+eG1wLmlpZDoyZjAxMTkxMy04Mjk1LTM5NDQtYmZmNi0xNjllM2FlNDk5OGU8L3N0RXZ0Omlu
    c3RhbmNlSUQ+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDp3aGVuPjIwMTctMDYtMDZUMTU6NTY6MTIrMDI6MDA8L3N0RXZ0OndoZW4+CiAgICAgICAg
    ICAgICAgICAgIDxzdEV2dDpzb2Z0d2FyZUFnZW50PkFkb2JlIFBob3Rvc2hvcCBDQyAyMDE3IChXaW5kb3dzKTwvc3RFdnQ6c29mdHdhcmVBZ2VudD4K
    ICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAg
    IDwvcmRmOlNlcT4KICAgICAgICAgPC94bXBNTTpIaXN0b3J5PgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgog
    ICAgICAgICA8dGlmZjpYUmVzb2x1dGlvbj43MjAwMDAvMTAwMDA8L3RpZmY6WFJlc29sdXRpb24+CiAgICAgICAgIDx0aWZmOllSZXNvbHV0aW9uPjcy
    MDAwMC8xMDAwMDwvdGlmZjpZUmVzb2x1dGlvbj4KICAgICAgICAgPHRpZmY6UmVzb2x1dGlvblVuaXQ+MjwvdGlmZjpSZXNvbHV0aW9uVW5pdD4KICAg
    ICAgICAgPGV4aWY6Q29sb3JTcGFjZT42NTUzNTwvZXhpZjpDb2xvclNwYWNlPgogICAgICAgICA8ZXhpZjpQaXhlbFhEaW1lbnNpb24+MTA5PC9leGlm
    OlBpeGVsWERpbWVuc2lvbj4KICAgICAgICAgPGV4aWY6UGl4ZWxZRGltZW5zaW9uPjg5PC9leGlmOlBpeGVsWURpbWVuc2lvbj4KICAgICAgPC9yZGY6
    RGVzY3JpcHRpb24+CiAgIDwvcmRmOlJERj4KPC94OnhtcG1ldGE+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAK
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    IAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAog
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAK
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
    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
  BASE64
  setting.save
end

Setting.set('invoice_reference', 'YYMMmmmX[/VL]R[/A]S[/E]') unless Setting.find_by(name: 'invoice_reference').try(:value)

Setting.set('invoice_code-active', true) unless Setting.find_by(name: 'invoice_code-active').try(:value)

Setting.set('invoice_code-value', 'FABMGRFABLAB') unless Setting.find_by(name: 'invoice_code-value').try(:value)

Setting.set('invoice_order-nb', 'nnnnnn-MM-YY') unless Setting.find_by(name: 'invoice_order-nb').try(:value)

Setting.set('invoice_VAT-active', false) unless Setting.find_by(name: 'invoice_VAT-active').try(:value)

Setting.set('invoice_VAT-rate', 20.0) unless Setting.find_by(name: 'invoice_VAT-rate').try(:value)

Setting.set('invoice_text', I18n.t('invoices.invoice_text_example')) unless Setting.find_by(name: 'invoice_text').try(:value)

unless Setting.find_by(name: 'invoice_legals').try(:value)
  setting = Setting.find_or_initialize_by(name: 'invoice_legals')
  setting.value = 'Fab-manager<br/>' \
                  '41 rue du Colonel Moutarde, 21000 DIJON France<br/>' \
                  'Tél. : +33 1 23 45 67 98<br/>' \
                  'Fax. : +33 1 23 45 67 98<br/>' \
                  'SIRET : 237 082 474 00006 - APE 913 E'
  setting.save
end

Setting.set('booking_window_start', '1970-01-01 08:00:00') unless Setting.find_by(name: 'booking_window_start').try(:value)

Setting.set('booking_window_end', '1970-01-01 23:59:59') unless Setting.find_by(name: 'booking_window_end').try(:value)

Setting.set('booking_move_enable', true) unless Setting.find_by(name: 'booking_move_enable').try(:value)

Setting.set('booking_move_delay', 24) unless Setting.find_by(name: 'booking_move_delay').try(:value)

Setting.set('booking_cancel_enable', false) unless Setting.find_by(name: 'booking_cancel_enable').try(:value)

Setting.set('booking_cancel_delay', 24) unless Setting.find_by(name: 'booking_cancel_delay').try(:value)

Setting.set('main_color', '#cb1117') unless Setting.find_by(name: 'main_color').try(:value)

Setting.set('secondary_color', '#ffdd00') unless Setting.find_by(name: 'secondary_color').try(:value)

Stylesheet.build_theme!
Stylesheet.build_home!

unless Setting.find_by(name: 'training_information_message').try(:value)
  setting = Setting.find_or_initialize_by(name: 'training_information_message')
  setting.value = "Avant de réserver une formation, nous vous conseillons de consulter nos offres d'abonnement qui" \
                  ' proposent des conditions avantageuses sur le prix des formations et les créneaux machines.'
  setting.save
end

Setting.set('fablab_name', 'Fab-manager') unless Setting.find_by(name: 'fablab_name').try(:value)

Setting.set('name_genre', 'male') unless Setting.find_by(name: 'name_genre').try(:value)

unless DatabaseProvider.count.positive?
  db_provider = DatabaseProvider.new
  db_provider.save

  unless AuthProvider.find_by(providable_type: DatabaseProvider.name)
    provider = AuthProvider.new
    provider.name = 'FabManager'
    provider.providable = db_provider
    provider.status = 'active'
    provider.save
  end
end

Setting.set('reminder_enable', true) unless Setting.find_by(name: 'reminder_enable').try(:value)

Setting.set('reminder_delay', 24) unless Setting.find_by(name: 'reminder_delay').try(:value)

Setting.set('visibility_yearly', 3) unless Setting.find_by(name: 'visibility_yearly').try(:value)

Setting.set('visibility_others', 1) unless Setting.find_by(name: 'visibility_others').try(:value)

Setting.set('display_name_enable', false) unless Setting.find_by(name: 'display_name_enable').try(:value)

Setting.set('machines_sort_by', 'default') unless Setting.find_by(name: 'machines_sort_by').try(:value)

unless Setting.find_by(name: 'privacy_draft').try(:value)
  setting = Setting.find_or_initialize_by(name: 'privacy_draft')
  setting.value = <<~HTML
    <p>La présente politique de confidentialité définit et vous informe de la manière dont _________ utilise et protège les
    informations que vous nous transmettez, le cas échéant, lorsque vous utilisez le présent site accessible à partir de l’URL suivante :
    _________ (ci-après le « Site »).</p><p>Veuillez noter que cette politique de confidentialité est susceptible d’être modifiée ou
    complétée à tout moment par _________, notamment en vue de se conformer à toute évolution législative, réglementaire, jurisprudentielle
    ou technologique. Dans un tel cas, la date de sa mise à jour sera clairement identifiée en tête de la présente politique et l'Utilisateur
    sera informé par courriel. Ces modifications engagent l’Utilisateur dès leur mise en ligne. Il convient par conséquent que l’Utilisateur
    consulte régulièrement la présente politique de confidentialité et d’utilisation des cookies afin de prendre connaissance de ses
    éventuelles modifications.</p><h3>I. DONNÉES PERSONNELLES</h3><p>D’une manière générale, il vous est possible de visiter le site de
    _________ sans communiquer aucune information personnelle vous concernant. En toute hypothèse, vous n’êtes en aucune manière obligé de
    transmettre ces informations à _________.</p><p>Néanmoins, en cas de refus, il se peut que vous ne puissiez pas bénéficier de
    certaines informations ou services que vous avez demandé. A ce titre en effet, _________ peut être amené dans certains cas à vous
    demander de renseigner vos nom, prénom, pseudonyme, sexe, adresse mail, numéro de téléphone, entreprise et date de naissance (ci-après
    vos « Informations Personnelles »). En fournissant ces informations, vous acceptez expressément qu’elles soient traitées par
    _________, aux fins indiquées au point 2 ci-dessous.</p><p>Conformément au Règlement Général sur la Protection des Données (General
    Data Protection Regulation) adopté par le Parlement européen le 14 avril 2016, et à la Loi Informatique et Libertés du 6 janvier 1978
    modifiée, _________ vous informe des points suivants :</p><h4>1. Identité du responsable du traitement</h4><p>Le responsable du
    traitement est (la société/l'association) _________ – (adresse) _________, (code postal) _________ (ville)&nbsp;_________ – (Pays)
    _________ .</p><h4>2. Finalités du traitement</h4><p>_________ est susceptible de traiter vos Informations Personnelles :</p><p>(a)
    aux fins de vous fournir les informations ou les services que vous avez demandés (notamment : l'envoi de notifications relatives à
    vos activités sur le Site, l’envoi de la Newsletter, la correspondance par email, l’envoi d’informations commerciales, livres
    blancs ou encore l’évaluation de votre niveau de satisfaction quant aux services proposés) ;</p><p>(b) aux fins de recueillir des
    informations nous permettant d’améliorer notre Site, nos produits et services (notamment par le biais de cookies) ;</p><p>(c)
    aux fins de pouvoir vous contacter à propos de différents événements relatifs à _________, incluant notamment la mise à jour des
    produits et le support client.</p><h4>3. Destinataires</h4><p>Seul _________ est destinataire de vos Informations Personnelles.
    Celles-ci, que ce soit sous forme individuelle ou agrégée, ne sont jamais transmises à un tiers, nonobstant les sous-traitants
    auxquels _________ fait appel (vous trouverez de plus amples informations à leur sujet au point 7 ci-dessous). Ni _________,
    ni l’un quelconque de ses sous-traitants, ne procèdent à la commercialisation des données personnelles des visiteurs et Utilisateurs de
    son Site.</p><h4>4. Durée de conservation</h4><p>Vos Informations Personnelles sont conservées par _________ uniquement pour le temps
    correspondant à la finalité de la collecte tel qu’indiqué en 2 ci-dessus qui ne saurait en tout état de cause excéder 36 mois.</p><h4>5.
    Droits Informatique et Libertés</h4><p>Vous disposez des droits suivants concernant vos Informations Personnelles, que vous pouvez exercer
    en nous écrivant à l’adresse postale mentionnée au point 1 ou en contactant le délégué à la protection des données, dont l'adresse est
    mentionnée ci-contre.</p><p><b>o Droit d’accès et de communication des données</b></p><p>Vous avez la faculté d’accéder aux Informations
    Personnelles qui vous concernent.</p><p>Cependant, en raison de l’obligation de sécurité et de confidentialité dans le traitement des
    données à caractère personnel qui incombe à _________, vous êtes informé que votre demande sera traitée sous réserve que vous apportiez la
    preuve de votre identité, notamment par la production d’un scan de votre titre d’identité valide (en cas de demande par voie électronique)
    ou d’une photocopie signée de votre titre d’identité valide (en cas de demande adressée par écrit).</p><p>_________ vous informe qu’il
    sera en droit, le cas échéant, de s’opposer aux demandes manifestement abusives (de par leur nombre, leur caractère répétitif ou
    systématique).</p><p>Pour vous aider dans votre démarche, notamment si vous désirez exercer votre droit d’accès par le biais d’une
    demande écrite à l’adresse postale mentionnée au point 1, vous trouverez en cliquant sur le <a
    href="https://www.cnil.fr/fr/modele/courrier/exercer-son-droit-dacces">lien</a> suivant un modèle de courrier élaboré par la Commission
    Nationale de l’Informatique et des Libertés (la « CNIL »).</p><p><b>o Droit de rectification des données</b></p><p>Au titre de ce droit,
    la législation vous habilite à demander la rectification, la mise à jour, le verrouillage ou encore l’effacement des données vous
    concernant qui peuvent s’avérer le cas échéant inexactes, erronées, incomplètes ou obsolètes.</p><p>Egalement, vous pouvez définir des
    directives générales et particulières relatives au sort des données à caractère personnel après votre décès. Le cas échéant, les héritiers
    d’une personne décédée peuvent exiger de prendre en considération le décès de leur proche et/ou de procéder aux mises à jour nécessaires.
    </p><p>Pour vous aider dans votre démarche, notamment si vous désirez exercer, pour votre propre compte ou pour le compte de l’un de vos
    proches défunt, votre droit de rectification par le biais d’une demande écrite à l’adresse postale mentionnée au point 1, vous trouverez
    en cliquant sur le <a href="https://www.cnil.fr/fr/modele/courrier/rectifier-des-donnees-inexactes-obsoletes-ou-perimees">lien</a>
    suivant un modèle de courrier élaboré par la CNIL.</p><p><b>o Droit d’opposition</b></p><p>L’exercice de ce droit n’est possible que dans
    l’une des deux situations suivantes :</p><p>Lorsque l’exercice de ce droit est fondé sur des motifs légitimes ; ou</p><p>Lorsque
    l’exercice de ce droit vise à faire obstacle à ce que les données recueillies soient utilisées à des fins de prospection commerciale.</p>
    <p>Pour vous aider dans votre démarche, notamment si vous désirez exercer votre droit d’opposition par le biais d’une demande écrite
    adressée à l’adresse postale indiquée au point 1, vous trouverez en cliquant sur le <a
    href="https://www.cnil.fr/fr/modele/courrier/supprimer-des-informations-vous-concernant-dun-site-internet">lien</a> suivant un modèle de
    courrier élaboré par la CNIL.</p><h4>6. Délais de réponse</h4><p> _________ s’engage à répondre à votre demande d’accès, de rectification
    ou d’opposition ou toute autre demande complémentaire  d’informations dans un délai raisonnable qui ne saurait dépasser 1 mois à compter
    de la réception de votre demande.</p><h4>7. Prestataires habilités et transfert vers un pays tiers de l’Union Européenne</h4><p>_________
    vous informe qu’il a recours à ses prestataires habilités pour faciliter le recueil et le traitement des données que vous nous avez
    communiqué. Ces prestataires peuvent être situés en dehors de  l’Union Européenne et ont communication des données recueillies par le
    biais des divers formulaires présents sur le Site.</p><p>_________ s’est préalablement assuré de la mise en œuvre par ses prestataires de
    garanties adéquates et du respect de conditions strictes en matière de confidentialité, d’usage et de protection des données. Tout
    particulièrement, la vigilance s’est portée sur l’existence d’un fondement légal pour effectuer un quelconque transfert de données vers un
    pays tiers. A ce titre, l’un de nos prestataires est soumis à (nom de la règle) _________ approuvées par la (nom de l'autorité) _________
    en (année d'approbation)&nbsp;_________.</p><h4>8. Plainte auprès de l’autorité compétente</h4><p>Si vous considérez que _________ ne
    respecte pas ses obligations au regard de vos Informations Personnelles, vous pouvez adresser une plainte ou une demande auprès de
    l’autorité compétente. En France, l’autorité compétente est la CNIL à laquelle vous pouvez adresser une demande par voie électronique en
    cliquant sur le lien suivant : <a href="https://www.cnil.fr/fr/plaintes/internet">https://www.cnil.fr/fr/plaintes/internet</a>.</p>
    <h3>II. POLITIQUE RELATIVE AUX COOKIES</h3><p>Lors de votre première connexion sur le site web de _________, vous êtes avertis par un
    bandeau en bas de votre écran que des informations relatives à votre navigation sont susceptibles d’être enregistrées dans des fichiers
    dénommés « cookies ». Notre politique d’utilisation des cookies vous permet de mieux comprendre les dispositions que nous mettons en œuvre
    en matière de navigation sur notre site web. Elle vous informe notamment sur l’ensemble des cookies présents sur notre site web, leur
    finalité (partie I.) et vous donne la marche à suivre pour les paramétrer (partie II.)</p><h4>1. Informations générales sur les cookies
    présents sur le site de _________</h4><p>_________, en tant qu’éditeur du présent site web, pourra procéder à l’implantation d’un cookie
    sur le disque dur de votre terminal (ordinateur, tablette, mobile etc.) afin de vous garantir une navigation fluide et optimale sur notre
    site Internet.</p><p>Les « cookies » (ou témoins de connexion) sont des petits fichiers texte de taille limitée qui nous permettent de
    reconnaître votre ordinateur, votre tablette ou votre mobile aux fins de personnaliser les services que nous vous proposons.</p><p>Les
    informations recueillies par le biais des cookies ne permettent en aucune manière de vous identifier nominativement. Elles sont utilisées
    exclusivement pour nos besoins propres afin d’améliorer l’interactivité et la performance de notre site web et de vous adresser des
    contenus adaptés à vos centres d’intérêts. Aucune de ces informations ne fait l’objet d’une communication auprès de tiers sauf lorsque
    _________ a obtenu au préalable votre consentement ou bien lorsque la divulgation de ces informations est requise par la loi, sur ordre
    d’un tribunal ou toute autorité administrative ou judiciaire habilitée à en connaître.</p><p>Pour mieux vous éclairer sur les informations
    que les cookies identifient, vous trouverez ci-dessous un tableau listant les différents types de cookies susceptibles d’être utilisés sur
    le site web de _________, leur nom, leur finalité ainsi que leur durée de conservation.</p><h4>2. Configuration de vos préférences sur les
    cookies</h4><p>Vous pouvez accepter ou refuser le dépôt de cookies à tout moment.</p><p>Lors de votre première connexion sur le site web
    de _________, une bannière présentant brièvement des informations relatives au dépôt de cookies et de technologies similaires apparaît en
    bas de votre écran. Cette bannière vous demande de choisir explicitement d'acceptez ou non le dépôt de cookies sur votre terminal.
    </p><p>Après avoir fait votre choix, vous pouvez le modifier ultérieurement&nbsp; en vous connectant à votre compte utilisateur puis en
    naviguant dans la section intitulée « mes paramètres&nbsp;», accessible via un clic sur votre nom, en haut à droite de l'écran.</p>
    <p>Selon le type de cookie en cause, le recueil de votre consentement au dépôt et à la lecture de cookies sur votre terminal peut être
    impératif.</p><h4>a. Les cookies exemptés de consentement</h4><p>Conformément aux recommandations de la Commission Nationale de
    l’Informatique et des Libertés (CNIL), certains cookies sont dispensés du recueil préalable de votre consentement dans la mesure où ils
    sont strictement nécessaires au fonctionnement du site internet ou ont pour finalité exclusive de permettre ou faciliter la communication
    par voie électronique.  Il s’agit des cookies suivants :</p><p><b>o Identifiant de session</b> et&nbsp;<b>authentification</b> sur l'API.
    Ces cookies sont intégralement soumis à la présente politique dans la mesure où ils sont émis et gérés par _________.</p><p>
    <b>o Stripe</b>, permettant de gérer les paiements par carte bancaire et dont la politique de confidentialité est accessible sur ce
    <a href="https://stripe.com/fr/privacy">lien</a>.</p><p><b>o Disqus</b>, permettant de poster des commentaires sur les fiches projet et
    dont la politique de confidentialité est accessible sur ce <a href="https://help.disqus.com/articles/1717103-disqus-privacy-policy">lien
    </a>.</p><h4>b. Les cookies nécessitant le recueil préalable de votre consentement</h4><p>Cette
    exigence concerne les cookies émis par des tiers et qui sont qualifiés de « persistants » dans la mesure où ils demeurent dans votre
    terminal jusqu’à leur effacement ou leur date d’expiration.</p><p>De tels cookies étant émis par des tiers, leur utilisation et leur dépôt
    sont soumis à leurs propres politiques de confidentialité dont vous trouverez un lien ci-dessous. Cette famille de cookie comprend les
    cookies de mesure d’audience (Google Analytics).</p><p>Les cookies de mesure d’audience établissent des statistiques concernant la
    fréquentation et l’utilisation de divers éléments du site web (comme les contenus/pages que vous avez visité).
    Ces données participent à l’amélioration de l’ergonomie du site web de _________. Un outil de mesure d’audience est utilisé sur le
    présent site internet :</p><p><b>o Google Analytics</b> pour gérer les statistiques de visites dont la politique de
    confidentialité est disponible (uniquement en anglais) à partir du <a href="https://policies.google.com/privacy?hl=fr&amp;gl=ZZ">lien
    </a> suivant. </p><h4>c. Vous disposez de divers outils de paramétrage des cookies</h4><p>La plupart
    des navigateurs Internet sont configurés par défaut de façon à ce que le dépôt de cookies soit autorisé. Votre navigateur vous offre
    l’opportunité de modifier ces paramètres standards de manière à ce que l’ensemble des cookies soit rejeté systématiquement ou bien à ce
    qu’une partie seulement des cookies soit acceptée ou refusée en fonction de leur émetteur.</p><p><b>ATTENTION</b> : Nous attirons votre
    attention sur le fait que le refus du dépôt de cookies sur votre terminal est néanmoins susceptible d’altérer votre expérience
    d’utilisateur ainsi que votre accès à certains services ou fonctionnalités du présent site web. Le cas échéant, _________ décline toute
    responsabilité concernant les conséquences liées à la dégradation de vos conditions de navigation qui interviennent en raison de votre
    choix de refuser, supprimer ou bloquer les cookies nécessaires au fonctionnement du site.
    Ces conséquences ne sauraient constituer un dommage et vous ne pourrez prétendre à aucune indemnité de ce fait.</p>
    <p>Votre navigateur vous permet également de supprimer les cookies existants sur votre
    terminal ou encore de vous signaler lorsque de nouveaux cookies sont susceptibles d’être déposés sur votre terminal. Ces paramètres n’ont
    pas d’incidence sur votre navigation mais vous font perdre tout le bénéfice apporté par le cookie.</p><p>Veuillez ci-dessous prendre
    connaissance des multiples outils mis à votre disposition afin que vous puissiez paramétrer les cookies déposés sur votre terminal.</p>
    <h4>d. Le paramétrage de votre navigateur Internet</h4><p>Chaque navigateur Internet propose ses propres paramètres de gestion des
    cookies. Pour savoir de quelle manière modifier vos préférences en matière de cookies, vous trouverez ci-dessous les liens vers l’aide
    nécessaire pour accéder au menu de votre navigateur prévu à cet effet :</p>
    <ul>
      <li><a href="https://support.google.com/chrome/answer/95647?hl=fr">Chrome</a></li>
      <li><a href="https://support.mozilla.org/fr/kb/activer-desactiver-cookies">Firefox</a></li>
      <li><a href="https://support.microsoft.com/fr-fr/help/17442/windows-internet-explorer-delete-manage-cookies#ie=ie-11">Internet
      Explorer</a></li>
      <li><a href="http://help.opera.com/Windows/10.20/fr/cookies.html">Opera</a></li>
      <li><a href="https://support.apple.com/kb/PH21411?viewlocale=fr_FR&amp;locale=fr_FR">Safari</a></li>
    </ul>
    <p>Pour de plus amples informations concernant les outils de maîtrise des cookies, vous pouvez consulter le
    <a href="https://www.cnil.fr/fr/cookies-les-outils-pour-les-maitriser">site internet</a> de la CNIL.</p>
  HTML
  setting.save
end

Setting.set('fab_analytics', true) unless Setting.find_by(name: 'fab_analytics').try(:value)

unless Setting.find_by(name: 'link_name').try(:value)
  include ApplicationHelper # rubocop:disable Style/MixinUsage

  name = Setting.get('fablab_name')
  gender = Setting.get('name_genre')
  setting = Setting.find_or_initialize_by(name: 'link_name')
  setting.value = _t('app.public.common.about_the_fablab', NAME: name, GENDER: gender)
  setting.save
end

unless Setting.find_by(name: 'home_content').try(:value)
  setting = Setting.find_or_initialize_by(name: 'home_content')
  setting.value = <<~HTML
    <div>
      <div class="m-sm">
        <div id="news">#{I18n.t('app.admin.settings.item_news')}</div>
      </div>
      <div class="row wrapper">
        <div class="col-lg-8">
          <div id="projects">#{I18n.t('app.admin.settings.item_projects')}</div>
        </div>
        <div class="col-lg-4 m-t-lg">
          <div id="twitter">#{I18n.t('app.admin.settings.item_twitter')}</div>
          <div id="members">#{I18n.t('app.admin.settings.item_members')}</div>
        </div>
      </div>
      <div class="row wrapper m-t-sm">
        <div class="col-lg-12">
          <div id="events">#{I18n.t('app.admin.settings.item_events')}</div>
        </div>
      </div>
    </div>
  HTML
  setting.save
end

Setting.set('slot_duration', 60) unless Setting.find_by(name: 'slot_duration').try(:value)

Setting.set('spaces_module', false) unless Setting.find_by(name: 'spaces_module').try(:value)

Setting.set('plans_module', true) unless Setting.find_by(name: 'plans_module').try(:value)

Setting.set('invoicing_module', true) unless Setting.find_by(name: 'invoicing_module').try(:value)

Setting.set('feature_tour_display', 'once') unless Setting.find_by(name: 'feature_tour_display').try(:value)

Setting.set('email_from', 'noreply@fab-manager.com') unless Setting.find_by(name: 'email_from').try(:value)

Setting.set('online_payment_module', false) unless Setting.find_by(name: 'online_payment_module').try(:value)

Setting.set('openlab_default', true) unless Setting.find_by(name: 'openlab_default').try(:value)

unless Setting.find_by(name: 'allowed_cad_extensions').try(:value)
  Setting.set(
    'allowed_cad_extensions',
    'pdf ai eps cad math svg stl dxf dwg obj step iges igs 3dm 3dmf doc docx png ino scad fcad skp sldprt sldasm slddrw' \
    'slddrt tex latex ps fcstd fcstd1'
  )
end

unless Setting.find_by(name: 'allowed_cad_mime_types').try(:value)
  Setting.set(
    'allowed_cad_mime_types',
    'application/pdf application/postscript application/illustrator image/x-eps image/svg+xml application/sla application/dxf ' \
    'application/acad application/dwg application/octet-stream application/step application/iges model/iges x-world/x-3dmf ' \
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document image/png text/x-arduino text/plain application/scad ' \
    'application/vnd.sketchup.skp application/x-koan application/vnd-koan koan/x-skm application/vnd.koan application/x-tex ' \
    'application/x-latex application/x-extension-fcstd'
  )
end

Setting.set('stripe_currency', 'EUR') unless Setting.find_by(name: 'stripe_currency').try(:value)

Setting.set('invoice_prefix', 'FabManager_invoice') unless Setting.find_by(name: 'invoice_prefix').try(:value)

Setting.set('payment_schedule_prefix', 'FabManager_paymentSchedule') unless Setting.find_by(name: 'payment_schedule_prefix').try(:value)

Setting.set('confirmation_required', false) unless Setting.find_by(name: 'confirmation_required').try(:value)

Setting.set('wallet_module', true) unless Setting.find_by(name: 'wallet_module').try(:value)

Setting.set('statistics_module', true) unless Setting.find_by(name: 'statistics_module').try(:value)

Setting.set('upcoming_events_shown', 'until_start') unless Setting.find_by(name: 'upcoming_events_shown').try(:value)

Setting.set('trainings_module', true) unless Setting.find_by(name: 'trainings_module').try(:value)

if StatisticCustomAggregation.count.zero?
  # available reservations hours for machines
  machine_hours = StatisticType.find_by(key: 'hour', statistic_index_id: 2)

  available_hours = StatisticCustomAggregation.new(
    statistic_type_id: machine_hours.id,
    es_index: 'fablab',
    es_type: 'availabilities',
    field: 'available_hours',
    query: '{"size":0, "aggregations":{"%{aggs_name}":{"sum":{"field":"bookable_hours"}}}, "query":{"bool":{"must":[{"range":' \
           '{"start_at":{"gte":"%{start_date}", "lte":"%{end_date}"}}}, {"match":{"available_type":"machines"}}]}}}'
  )
  available_hours.save!

  # available training tickets
  training_bookings = StatisticType.find_by(key: 'booking', statistic_index_id: 3)

  available_tickets = StatisticCustomAggregation.new(
    statistic_type_id: training_bookings.id,
    es_index: 'fablab',
    es_type: 'availabilities',
    field: 'available_tickets',
    query: '{"size":0, "aggregations":{"%{aggs_name}":{"sum":{"field":"nb_total_places"}}}, "query":{"bool":{"must":[{"range":' \
           '{"start_at":{"gte":"%{start_date}", "lte":"%{end_date}"}}}, {"match":{"available_type":"training"}}]}}}'
  )
  available_tickets.save!
end

unless StatisticIndex.find_by(es_type_key: 'space')
  index = StatisticIndex.create!(es_type_key: 'space', label: I18n.t('statistics.spaces'))
  StatisticType.create!([
                          { statistic_index_id: index.id, key: 'booking', label: I18n.t('statistics.bookings'),
                            graph: true, simple: true },
                          { statistic_index_id: index.id, key: 'hour', label: I18n.t('statistics.hours_number'),
                            graph: true, simple: false }
                        ])
end
