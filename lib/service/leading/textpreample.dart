import 'package:aahelper/helper/stylemenu.dart';
import 'package:aahelper/service/leading/textappealtonewbie.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TextPreamble extends StatelessWidget {
  final String namegroup;
  final String nameleading;
  const TextPreamble(
      {super.key, required this.namegroup, required this.nameleading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          RichText(
            softWrap: true,
            textAlign: TextAlign.start,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.black,
              ),
              children: <TextSpan>[
                const TextSpan(
                    text:
                        '   Добро пожаловать на собрание группы Анонимных Алкоголиков ',
                    style: AppTextStyle.valuesstyle),
                TextSpan(
                  text: ' $namegroup \n\n',
                  style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
                const TextSpan(
                  text: 'Здравствуйте! Меня зовут ',
                  style: AppTextStyle.valuesstyle,
                ),
                TextSpan(
                  text: nameleading,
                  style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
                const TextSpan(
                    text: ' и я алкоголик. \n\n',
                    style: AppTextStyle.valuesstyle),
                const TextSpan(
                  style: AppTextStyle.spantextstyle,
                  children: <TextSpan>[
                    TextSpan(
                        text:
                            'Анонимные Алкоголики — это содружество, объединяющее мужчин и женщин, которые делятся друг с другом своим опытом, силами и надеждами с целью помочь себе и другим избавиться от алкоголизма.\n\n'),
                    TextSpan(
                        text:
                            'Единственное условие для членства — это желание бросить пить. Члены АА не платят ни вступительных, ни членских взносов. Мы сами себя содержим благодаря нашим добровольным пожертвованиям.\n\n'),
                    TextSpan(
                        text:
                            'АА не связано ни с какой сектой, вероисповеданием, политическим направлением, организацией или учреждением; не вступает в полемику, по каким бы то ни было вопросам, не поддерживает и не выступает, против чьих бы то ни было интересов.\n\n'),
                    TextSpan(
                        text:
                            'Наша основная цель – остаться трезвыми и помочь другим алкоголикам обрести трезвость.\n\n'),
                    TextSpan(
                        text:
                            'Отключите, пожалуйста, звуковые сигналы мобильных телефонов. Давайте начнём нашу встречу с минуты молчания. Вспомним о тех, кто болен этой страшной болезнью, кто умер от неё, кто в срыве, кто ищет дорогу к нам, о тех, кто ещё не знает о нас, и приготовимся к собранию. \n\n'),
                  ],
                ),
                const TextSpan(
                  text: 'Минута молчания \n\n',
                  style: TextStyle(
                      fontSize: 16.0,
                      fontStyle: FontStyle.italic,
                      decoration: TextDecoration.underline),
                ),
                const TextSpan(
                  text: 'Спасибо. \n\n',
                  style: AppTextStyle.valuesstyle,
                ),
                const TextSpan(
                  text:
                      '   Зачитывается отрывок из пятой главы «Большой Книги». \n\n',
                  style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
                const TextSpan(
                  style: AppTextStyle.spantextstyle,
                  children: [
                    TextSpan(
                        text:
                            '   Мы редко встречали человека, который бы строго следовал по нашему пути и потерпел неудачу. '
                            ' Не излечиваются те люди, которые не могут или не хотят целиком подчинить свою жизнь этой простой программе; обычно это мужчины и женщины, которые органически не могут быть честными сами с собой. '
                            ' Такие несчастные есть. Они не виноваты; похоже, что они просто родились такими. Они по натуре своей не способны усвоить и поддерживать образ жизни, требующий неумолимой честности. '
                            ' Вероятность их выздоровления ниже средней. Есть люди, страдающие от серьезных эмоциональных и психических расстройств, но многие из них все-таки выздоравливают, если у них есть такое качество как честность. \n'),
                    TextSpan(
                        text:
                            '   Истории из нашей жизни рассказывают в общих чертах, какими мы были, что с нами произошло и какими мы стали. '
                            'Если Вы решили, что хотите обрести то же, что и мы, и у вас появилось желание сделать все ради достижения цели, значит, вы готовы предпринять определенные шаги. \n'),
                    TextSpan(
                        text:
                            '   Некоторым из них мы противились. Мы думали, что можно найти более легкий, удобный путь. Но мы такого не нашли. Со всей серьезностью мы просим вас быть с самого начала бесстрашными в выполнении этих шагов и следовать им неуклонно. '
                            'Некоторые из нас старались придерживаться своих старых представлений и не добились никакого результата, пока полностью не отказались от них. \n'),
                    TextSpan(
                        text:
                            '   Помните, что мы имеем дело с алкоголем хитрым, властным, сбивающим с толку! Без помощи нам с ним не совладать. Но есть Некто всесильный это Бог. Да обретете вы Его ныне! \n'),
                    TextSpan(
                        text:
                            '   Полумеры ничем не помогли нам. Мы подошли к поворотному моменту. Все, отринув, мы просили Его о попечении и защите. \n\n'),
                  ],
                ),
                const TextSpan(
                  text:
                      'Вот предпринятые нами шаги, которые предлагаются как программа выздоровления. И традиции, благодаря которым, существует наше сообщество. \n\n',
                  style: AppTextStyle.valuesstyle,
                ),
                const TextSpan(
                  text: '   Зачитываются по кругу 12 Шагов и 12 Традиций. \n\n',
                  style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
                const TextSpan(
                  text:
                      '   Многие из нас восклицали: “Что за режим! Я не смогу следовать ему до конца”. Не отчаивайтесь. '
                      'Никто из нас не смог совершенно безупречно придерживаться этих принципов. Мы не святые. '
                      'Главное в том, что мы хотим духовно развиваться. Изложенные принципы являются руководством на пути прогресса. Мы притязаем лишь на духовный прогресс, а не на духовное совершенство. \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text:
                      '   Наше описание алкоголика, глава, обращённая к агностику, а также истории из нашей личной жизни до и после принятия программы выявили три существенных момента: \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                    text:
                        '   А) Мы были алкоголиками и не могли управлять своей жизнью. \n'
                        'Б) Возможно, никакая человеческая сила не смогла бы избавить нас от алкоголизма. \n'
                        'В) Бог мог избавить и избавит, если Его искать. \n\n',
                    style: AppTextStyle.valuesstyle),
                const TextSpan(
                  text: 'Сегодня у нас открытое собрание. '
                      'Это означает, что присутствовать могут все, кого интересует выздоровление от алкоголизма, но высказываться могут только алкоголики. Собрание проходит с 19:00 до 20:15. /n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text:
                      'Для удобства общения давайте представимся по кругу и напомним себе и другим о причине, по которой Мы здесь собрались. '
                      'Так как эта группа Анонимных Алкоголиков, и в целях экономии времени, просьба другие зависимости не называть.  \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text: '   ПРЕДСТАВЛЯЮТСЯ. \n\n',
                  style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
                const TextSpan(
                    text:
                        ' Если кто впервые пришел на собрание группы АА, представьтесь, пожалуйста, чтобы мы могли Вас поприветствовать. \n\n',
                    style: AppTextStyle.valuesstyle),
                TextSpan(
                  text: '   Зачитывается обращение к новичкам. \n\n',
                  style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Обработчик нажатия для перехода на другой экран
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppealToNewbie(),
                        ),
                      );
                    },
                ),
                const TextSpan(
                    text: ' А кто первый раз на собрании нашей группы? \n',
                    style: AppTextStyle.valuesstyle),
                const TextSpan(
                  text: ' (Записать новичков в тетрадь)\n\n',
                  style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
                const TextSpan(
                    text: ' Как проходит наше собрание: \n',
                    style: AppTextStyle.valuesstyle),
                const TextSpan(
                  text:
                      '   На собраниях нашей группы мы предпочитаем делиться своим личным опытом выздоровления от алкоголизма,'
                      'а не употребления алкоголя и других наркотиков. Постарайтесь не упоминать других зависимостей. \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text:
                      '   Мы стараемся соблюдать анонимность, и не называем имён, фамилий, должностей, названий групп, учреждений и реабилитационных центров. \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text:
                      '   Мы обращаемся к друг другу по имени и на Ты. Перед Болезнью все равны! \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text:
                      '   Здесь Мы не затрагиваем религиозных, политических, и расовых вопросов. '
                      'Мы предпочитаем говорить о себе, своих проблемах, а не о проблемах других людей. \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text:
                      '   Воздерживайтесь от посторонних слов, советов, обратной связи, прерываний или критических комментариев. '
                      'Избегая посторонних высказываний, мы создаём безопасную атмосферу на нашей группе и устраняем возможность повторения случаев, '
                      'когда нас не слушали, высмеивали, критиковали и унижали. Мы принимаем, друг друга такими, какие мы есть. \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text:
                      ' Те, кто употреблял сегодня алкоголь или другие вещества, изменяющие сознание, '
                      'могут присутствовать на собрании, но не высказываться, и не мешать другим. \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text:
                      '   Просьба воздержаться от использования мобильных телефонов во время собрания – Ваше внимание и участие нужны другим членам группы. \n\n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                    text:
                        ' Поделитесь радостью, есть ли у кого сегодня юбилей трезвости? \n\n',
                    style: AppTextStyle.valuesstyle),
                const TextSpan(
                    text: ' Тема сегодняшнего собрания.... \n',
                    style: AppTextStyle.valuesstyle),
                const TextSpan(
                  text: ' (Зачитываются темы собрания )\n\n',
                  style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
                const TextSpan(
                  text:
                      '   Добро пожаловать высказываться по прочитанному и предложенным темам. \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text:
                      '       Мы высказываемся по кругу, не ссылаясь на чужие выступления и не комментируя их.'
                      'Выступая, помните о времени (регламент выступления определяет ведущий – примерно 5 минут), чтобы возможность высказаться была у каждого! \n\n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text: ' ОБЪЯВЛЕНИЯ \n\n',
                  style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
                const TextSpan(
                  text:
                      '   1. Согласно 7-ой Традиции Мы покрываем все свои расходы благодаря нашим добровольным пожертвованиям, которые не являются обязательными для членства в АА.'
                      ' Размер пожертвований каждый определяет для себя сам.'
                      '«Самообеспечение начинается с меня, ибо я являюсь частью нас — группы. Мы оплачиваем расходы группы, покупаем кофе, чай, сладости и литературу АА. '
                      'Мы оказываем поддержку своему районному комитету, Интергруппе Москвы и Российскому совету обслуживания АА, принимаем участие в донесении идей АА. '
                      'Если бы не все эти структуры, множество новичков так и не открыли бы для себя чуда АА». \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text:
                      '   2. Есть ли у кого-либо непреодолимое желание высказаться? (Если остается несколько минут).\n',
                  style: AppTextStyle.spantextstyle,
                ),
                TextSpan(
                  text:
                      '   3. Есть ли кого-нибудь объявления, касающиеся сообщества Анонимных Алкоголиков и группы  $namegroup в частности. \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text:
                      '   4. Кто готов стать наставником — просьба поднять руки. Тем, кому нужна помощь в прохождении Шагов, пожалуйста, обратитесь к этим людям. \n',
                  style: AppTextStyle.spantextstyle,
                ),
                TextSpan(
                  text:
                      '   5. Просьба сохранять порядок и спокойствие на территории группы $namegroup, отходить курить за угол дома, а также помочь привести в порядок помещение. \n',
                  style: AppTextStyle.spantextstyle,
                ),
                TextSpan(
                  text:
                      '   6. Поздравляем Юбиляров и Новичков, а также тех, кто впервые пришел на собрание группы $namegroup. \n\n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text: ' Заключение собрания . \n\n',
                  style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
                const TextSpan(
                  text:
                      '   В заключении собрания я хочу добавить, что мнения, выраженные здесь — это мнения только тех, кто говорил, а не АА в целом.'
                      'Примите то, что Вам понравилось, и отбросьте остальное. Истории, услышанные Вами, были рассказаны в доверии. '
                      'Сохраните их только в стенах этой комнаты и в Вашем сознании. \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text:
                      '   Мы познáем новую свободу и новое счастье. Мы не будем сожалеть о нашем прошлом и вместе с тем не захотим полностью забывать о нем. '
                      'Мы узнаем, что такое чистота, ясность, покой. Как бы низко мы ни пали в прошлом, мы поймем, как наш опыт может быть полезен другим.  '
                      'Исчезнут ощущения ненужности и жалости к себе. Мы потеряем интерес к вещам, которые подогревают наше самолюбие, и в нас усилится интерес к другим людям. '
                      'Мы освободимся от эгоизма. Изменится наше мировоззрение, исчезнут страх перед людьми и неуверенность в экономическом благополучии. '
                      'Мы интуитивно будем знать, как вести себя в ситуациях, которые раньше нас озадачивали. Мы поймем, что Бог делает для нас то, что мы не смогли сами сделать для себя.\n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text: '   Не слишком ли это звучит многообещающе? Нет. '
                      'Все это произошло со многими из нас, с одними раньше, с другими позже.  '
                      'Все это становится явью, если приложить усилия. \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text: '   Желающие могут присоединиться к нашей молитве: \n',
                  style: AppTextStyle.spantextstyle,
                ),
                const TextSpan(
                  text: ' Молитва о Душевном Покое. \n\n',
                  style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
